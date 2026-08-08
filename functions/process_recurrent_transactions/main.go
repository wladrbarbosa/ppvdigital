package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/appwrite/sdk-for-go/v5/appwrite"
	"github.com/appwrite/sdk-for-go/v5/query"
	"github.com/open-runtimes/types-for-go/v4/openruntimes"
)

var (
	dialer = &net.Dialer{
		Timeout:   30 * time.Second,
		KeepAlive: 30 * time.Second,
	}
)

func init() {
	// Globally override the DNS resolution to point to the docker bridge gateway
	// or APPWRITE_API_ENDPOINT_OVERRIDE IP for self-hosted instances.
	if transport, ok := http.DefaultTransport.(*http.Transport); ok {
		transport.DialContext = func(ctx context.Context, network, addr string) (net.Conn, error) {
			if strings.HasPrefix(addr, "appwrite.wladapps.com:") {
				// Determine target IP
				targetIP := os.Getenv("APPWRITE_API_ENDPOINT_OVERRIDE")
				if targetIP == "" {
					targetIP = getDefaultGateway()
				}
				if targetIP == "" {
					targetIP = "172.18.0.1" // Fallback
				}
				
				// Strip http:// or https:// if user accidentally included it in override
				targetIP = strings.TrimPrefix(targetIP, "http://")
				targetIP = strings.TrimPrefix(targetIP, "https://")
				targetIP = strings.Split(targetIP, "/")[0] // Strip any path

				port := strings.Split(addr, ":")[1]
				addr = fmt.Sprintf("%s:%s", targetIP, port)
			}
			return dialer.DialContext(ctx, network, addr)
		}
	}
}

const (
	DatabaseID     = "671f6e1600022832cba5"
	TransactionColl = "671f7a6f000cb3ab17b9"
	RecurrenceColl  = "transacao_recorrencia"
	DivisionsColl   = "divisao_transacoes"
)

func Main(Context openruntimes.Context) openruntimes.Response {
	// Initialize Appwrite Client using Dynamic API Keys & Endpoint guidelines
	appwriteEndpoint := os.Getenv("APPWRITE_ENDPOINT")
	if appwriteEndpoint == "" {
		appwriteEndpoint = os.Getenv("APPWRITE_FUNCTION_API_ENDPOINT")
	}

	// In self-hosted Appwrite Docker behind YunoHost, the external domain appwrite.wladapps.com
	// might not be reachable from the isolated function network (hairpin NAT issues).
	// We force the endpoint to be the public domain to preserve SNI/Host headers for YunoHost,
	// and let our init() DNS override handle routing the traffic directly to the host IP.
	if appwriteEndpoint == "" || strings.Contains(appwriteEndpoint, "appwrite.wladapps.com") || appwriteEndpoint == "http://appwrite/v1" {
		appwriteEndpoint = "https://appwrite.wladapps.com/v1"
	}
	projectID := os.Getenv("APPWRITE_FUNCTION_PROJECT_ID")
	
	// Get API key from environment or from request headers if using Dynamic Keys
	apiKey := os.Getenv("APPWRITE_API_KEY")
	if apiKey == "" {
		apiKey = Context.Req.Headers["x-appwrite-key"]
	}

	if projectID == "" || apiKey == "" {
		Context.Error("Missing required credentials: projectID or apiKey (from environment or x-appwrite-key header)")
		return Context.Res.Json(map[string]interface{}{
			"success": false,
			"error":   "Missing credentials",
		})
	}

	appClient := appwrite.NewClient(
		appwrite.WithEndpoint(appwriteEndpoint),
		appwrite.WithProject(projectID),
		appwrite.WithKey(apiKey),
		appwrite.WithSelfSigned(true),
	)

	dbService := appwrite.NewDatabases(appClient)

	Context.Log("Starting generation of infinite recurring transactions (v5 SDK)...")

	// 1. Fetch all recurrent rules where totalParcelas is null (indefinite recurrence)
	var recurrences []interface{}
	cursor := ""
	for {
		queries := []string{
			query.IsNull("totalParcelas"),
			query.Limit(100),
		}
		if cursor != "" {
			queries = append(queries, query.CursorAfter(cursor))
		}

		res, err := dbService.ListDocuments(
			DatabaseID,
			RecurrenceColl,
			dbService.WithListDocumentsQueries(queries),
		)
		if err != nil {
			Context.Error(fmt.Sprintf("Error fetching recurrences: %v", err))
			return Context.Res.Json(map[string]interface{}{
				"success": false,
				"error":   err.Error(),
			})
		}

		// Convert Documents slice to interface slice for processing
		// In v5 SDK, res.Documents is accessible
		var documents []interface{}
		resBytes, marshalErr := json.Marshal(res)
		if marshalErr == nil {
			var resMap map[string]interface{}
			if json.Unmarshal(resBytes, &resMap) == nil {
				if docsVal, ok := resMap["documents"].([]interface{}); ok {
					documents = docsVal
				}
			}
		}

		if len(documents) == 0 {
			break
		}

		for _, doc := range documents {
			recurrences = append(recurrences, doc)
		}

		cursor = getDocumentID(documents[len(documents)-1])
	}

	Context.Log(fmt.Sprintf("Found %d indefinite recurrence rules.", len(recurrences)))

	createdCount := 0
	errorCount := 0
	now := time.Now().UTC()
	startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)

	// 2. Process each recurrence rule concurrently
	var wg sync.WaitGroup
	semaphore := make(chan struct{}, 15) // Limit to 15 concurrent API requests
	var mu sync.Mutex

	for _, recDoc := range recurrences {
		wg.Add(1)
		semaphore <- struct{}{} // acquire token

		go func(recDoc interface{}) {
			defer wg.Done()
			defer func() { <-semaphore }() // release token
		recID := getDocumentID(recDoc)
		tipoRecorrencia := getStringAttribute(recDoc, "tipoRecorrencia")
		if tipoRecorrencia == "" {
			tipoRecorrencia = "mês" // Default to month
		}
		freq := getIntAttribute(recDoc, "frequencia")
		if freq <= 0 {
			freq = 1
		}

		// Check if current date matches an installment date for this recurrence
		todayTxRes, err := dbService.ListDocuments(
			DatabaseID,
			TransactionColl,
			dbService.WithListDocumentsQueries([]string{
				query.Equal("recorrencia", recID),
				query.StartsWith("dataCompetencia", startOfDay.Format("2006-01-02")),
				query.Limit(1),
			}),
		)
		if err != nil {
			Context.Error(fmt.Sprintf("Error checking today's transaction for recurrence %s: %v", recID, err))
			mu.Lock()
			errorCount++
			mu.Unlock()
			return
		}

		var todayDocuments []interface{}
		if todayBytes, err := json.Marshal(todayTxRes); err == nil {
			var todayMap map[string]interface{}
			if json.Unmarshal(todayBytes, &todayMap) == nil {
				if docsVal, ok := todayMap["documents"].([]interface{}); ok {
					todayDocuments = docsVal
				}
			}
		}

		if len(todayDocuments) == 0 {
			Context.Log(fmt.Sprintf("No installment cycle matches today (%s) for recurrence %s. Skipping.", startOfDay.Format("2006-01-02"), recID))
			return
		}

		// Query the latest transaction associated with this recurrence rule to extend it
		txRes, err := dbService.ListDocuments(
			DatabaseID,
			TransactionColl,
			dbService.WithListDocumentsQueries([]string{
				query.Equal("recorrencia", recID),
				query.OrderDesc("dataCompetencia"),
				query.Limit(1),
			}),
		)
		if err != nil {
			Context.Error(fmt.Sprintf("Error fetching latest transaction for recurrence %s: %v", recID, err))
			mu.Lock()
			errorCount++
			mu.Unlock()
			return
		}

		var txDocuments []interface{}
		txResBytes, marshalErr := json.Marshal(txRes)
		if marshalErr == nil {
			var txResMap map[string]interface{}
			if json.Unmarshal(txResBytes, &txResMap) == nil {
				if docsVal, ok := txResMap["documents"].([]interface{}); ok {
					txDocuments = docsVal
				}
			}
		}

		if len(txDocuments) == 0 {
			Context.Log(fmt.Sprintf("No transactions found for recurrence %s. Skipping.", recID))
			return
		}

		latestTx := txDocuments[0]
		latestTxID := getDocumentID(latestTx)
		latestDate := parseTransactionDate(latestTx, Context)

		// Calculate the next competency date
		var nextDate time.Time
		switch tipoRecorrencia {
		case "dia":
			nextDate = latestDate.AddDate(0, 0, freq)
		case "semana":
			nextDate = latestDate.AddDate(0, 0, 7*freq)
		case "mês":
			nextDate = latestDate.AddDate(0, freq, 0)
		case "ano":
			nextDate = latestDate.AddDate(freq, 0, 0)
		default:
			nextDate = latestDate.AddDate(0, freq, 0)
		}

		// Extract fields to clone from the latest transaction
		descricao := getStringAttribute(latestTx, "descricao")
		valor := getFloatAttribute(latestTx, "valor")
		tipo := getStringAttribute(latestTx, "tipo")
		conta := getRelationID(latestTx, "conta")
		contaDestino := getRelationID(latestTx, "contaDestino")
		categoria := getRelationID(latestTx, "categoria")
		devedorContato := getRelationID(latestTx, "devedorContato")
		credorContato := getRelationID(latestTx, "credorContato")

		// Prepare new transaction data map
		newTxData := map[string]interface{}{
			"descricao":       descricao,
			"valor":           valor,
			"tipo":            tipo,
			"dataCompetencia": nextDate.Format(time.RFC3339),
			"consolidada":     false, // Future transactions are not consolidated by default
			"recorrencia":     recID,
		}
		if conta != "" {
			newTxData["conta"] = conta
		}
		if contaDestino != "" {
			newTxData["contaDestino"] = contaDestino
		}
		if categoria != "" {
			newTxData["categoria"] = categoria
		}
		if devedorContato != "" {
			newTxData["devedorContato"] = devedorContato
		}
		if credorContato != "" {
			newTxData["credorContato"] = credorContato
		}

		// Create the new cloned transaction
		newTx, err := dbService.CreateDocument(
			DatabaseID,
			TransactionColl,
			"unique()",
			newTxData,
		)
		if err != nil {
			Context.Error(fmt.Sprintf("Failed to create new transaction for recurrence %s: %v", recID, err))
			mu.Lock()
			errorCount++
			mu.Unlock()
			return
		}

		newTxID := getDocumentID(newTx)
		Context.Log(fmt.Sprintf("Cloned transaction %s to %s with competency date %s", latestTxID, newTxID, nextDate.Format("2006-01-02")))

		// 3. Clone division of transactions if any exist for the latest transaction
		divRes, err := dbService.ListDocuments(
			DatabaseID,
			DivisionsColl,
			dbService.WithListDocumentsQueries([]string{
				query.Equal("transacao", latestTxID),
				query.Limit(100),
			}),
		)
		if err != nil {
			Context.Error(fmt.Sprintf("Error fetching divisions for transaction %s: %v", latestTxID, err))
			mu.Lock()
			errorCount++
			mu.Unlock()
			return
		}

		var divDocuments []interface{}
		divResBytes, marshalErr := json.Marshal(divRes)
		if marshalErr == nil {
			var divResMap map[string]interface{}
			if json.Unmarshal(divResBytes, &divResMap) == nil {
				if docsVal, ok := divResMap["documents"].([]interface{}); ok {
					divDocuments = docsVal
				}
			}
		}

		for _, divDoc := range divDocuments {
			contatoResponsavel := getRelationID(divDoc, "contatoResponsavel")
			peso := getFloatAttribute(divDoc, "peso")

			newDivData := map[string]interface{}{
				"transacao":          newTxID,
				"contatoResponsavel": contatoResponsavel,
				"peso":               peso,
			}

			_, err = dbService.CreateDocument(
				DatabaseID,
				DivisionsColl,
				"unique()",
				newDivData,
			)
			if err != nil {
				Context.Error(fmt.Sprintf("Failed to clone division %s for new transaction %s: %v", getDocumentID(divDoc), newTxID, err))
				errorCount++
			} else {
				Context.Log(fmt.Sprintf("Cloned division for new transaction %s (contact: %s, weight: %.2f)", newTxID, contatoResponsavel, peso))
			}
		}

		mu.Lock()
			createdCount++
			mu.Unlock()
		}(recDoc)
	}

	wg.Wait()

	Context.Log(fmt.Sprintf("Finished. Created: %d, Errors: %d", createdCount, errorCount))

	return Context.Res.Json(map[string]interface{}{
		"success":      true,
		"createdCount": createdCount,
		"errorCount":   errorCount,
	})
}

// Utility Helper Functions to handle dynamic Document interfaces gracefully

func getAttribute(doc interface{}, key string) interface{} {
	docJSON, err := json.Marshal(doc)
	if err != nil {
		return nil
	}

	var flatMap map[string]interface{}
	if err := json.Unmarshal(docJSON, &flatMap); err == nil {
		if val, exists := flatMap[key]; exists {
			return val
		}
		// If nested under a "data" map (standard Appwrite Go SDK structure)
		if dataVal, exists := flatMap["data"]; exists {
			if dataMap, ok := dataVal.(map[string]interface{}); ok {
				if val, exists := dataMap[key]; exists {
					return val
				}
			}
		}
	}
	return nil
}

func getDocumentID(doc interface{}) string {
	docJSON, err := json.Marshal(doc)
	if err != nil {
		return ""
	}

	var flatMap map[string]interface{}
	if err := json.Unmarshal(docJSON, &flatMap); err == nil {
		if id, ok := flatMap["$id"].(string); ok {
			return id
		}
		if id, ok := flatMap["id"].(string); ok {
			return id
		}
	}
	return ""
}

func getStringAttribute(doc interface{}, key string) string {
	val := getAttribute(doc, key)
	if val == nil {
		return ""
	}
	if strVal, ok := val.(string); ok {
		return strVal
	}
	return ""
}

func getFloatAttribute(doc interface{}, key string) float64 {
	val := getAttribute(doc, key)
	if val == nil {
		return 0.0
	}
	switch v := val.(type) {
	case float64:
		return v
	case int:
		return float64(v)
	case int64:
		return float64(v)
	}
	return 0.0
}

func getIntAttribute(doc interface{}, key string) int {
	val := getAttribute(doc, key)
	if val == nil {
		return 0
	}
	switch v := val.(type) {
	case int:
		return v
	case float64:
		return int(v)
	case int64:
		return int(v)
	}
	return 0
}

func getRelationID(doc interface{}, key string) string {
	val := getAttribute(doc, key)
	if val == nil {
		return ""
	}
	if strVal, ok := val.(string); ok {
		return strVal
	}
	if mapVal, ok := val.(map[string]interface{}); ok {
		if id, ok := mapVal["$id"].(string); ok {
			return id
		}
		if id, ok := mapVal["id"].(string); ok {
			return id
		}
	}
	return ""
}

// Helper to get default gateway IP from /proc/net/route for Linux containers
func getDefaultGateway() string {
	data, err := os.ReadFile("/proc/net/route")
	if err != nil {
		return ""
	}
	for _, line := range strings.Split(string(data), "\n") {
		fields := strings.Fields(line)
		if len(fields) >= 3 && fields[1] == "00000000" {
			var a, b, c, d int
			fmt.Sscanf(fields[2], "%02x%02x%02x%02x", &a, &b, &c, &d)
			return fmt.Sprintf("%d.%d.%d.%d", d, c, b, a)
		}
	}
	return ""
}

func parseTransactionDate(doc interface{}, Context openruntimes.Context) time.Time {
	// Try primary dataCompetencia first, then fallback to $createdAt, then $updatedAt
	raw := getStringAttribute(doc, "dataCompetencia")
	txID := getDocumentID(doc)

	if raw == "" {
		raw = getStringAttribute(doc, "$createdAt")
	}
	if raw == "" {
		raw = getStringAttribute(doc, "$updatedAt")
	}

	raw = strings.TrimSpace(raw)
	if raw == "" {
		Context.Log(fmt.Sprintf("Warning: transaction %s has no dataCompetencia, $createdAt, or $updatedAt. Fallback to current time.", txID))
		return time.Now().UTC()
	}

	// Supported time formats
	layouts := []string{
		time.RFC3339,
		"2006-01-02T15:04:05.000Z07:00",
		"2006-01-02T15:04:05.999999999Z07:00",
		"2006-01-02T15:04:05.000Z",
		"2006-01-02T15:04:05.000",
		"2006-01-02T15:04:05Z",
		"2006-01-02T15:04:05",
		"2006-01-02 15:04:05",
		"2006-01-02",
	}

	for _, layout := range layouts {
		if t, err := time.Parse(layout, raw); err == nil {
			return t.UTC()
		}
	}

	if len(raw) >= 10 {
		if t, err := time.Parse("2006-01-02", raw[:10]); err == nil {
			return t.UTC()
		}
	}

	Context.Log(fmt.Sprintf("Warning: unable to parse date '%s' for transaction %s. Fallback to current time.", raw, txID))
	return time.Now().UTC()
}