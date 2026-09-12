package handler

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/appwrite/sdk-for-go/v5/appwrite"
	"github.com/appwrite/sdk-for-go/v5/client"
	"github.com/appwrite/sdk-for-go/v5/models"
	"github.com/appwrite/sdk-for-go/v5/query"
	"github.com/open-runtimes/types-for-go/v4/openruntimes"
)

var (
	dialer = &net.Dialer{
		Timeout:   30 * time.Second,
		KeepAlive: 30 * time.Second,
	}
)

func configureAppClient(clt *client.Client, Context openruntimes.Context) {
	targetIP := os.Getenv("APPWRITE_API_ENDPOINT_OVERRIDE")
	targetIP = strings.TrimPrefix(targetIP, "http://")
	targetIP = strings.TrimPrefix(targetIP, "https://")
	targetIP = strings.Split(targetIP, "/")[0]
	targetIP = strings.TrimSpace(targetIP)

	if targetIP == "" || targetIP == "0.0.0.0" || targetIP == "localhost" || targetIP == "127.0.0.1" || targetIP == "::1" || strings.Contains(targetIP, "appwrite.wladapps.com") {
		targetIP = getDefaultGateway()
	}
	if targetIP == "" || targetIP == "0.0.0.0" || targetIP == "localhost" || targetIP == "127.0.0.1" || targetIP == "::1" || strings.Contains(targetIP, "appwrite.wladapps.com") {
		targetIP = "172.18.0.1" // Docker bridge fallback
	}

	Context.Log(fmt.Sprintf("Configuring client transport. Host gateway IP: %s", targetIP))

	customTransport := &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			origAddr := addr
			host, port, err := net.SplitHostPort(addr)
			if err == nil {
				if host == "appwrite.wladapps.com" || host == "localhost" || host == "127.0.0.1" || host == "::1" {
					addr = net.JoinHostPort(targetIP, port)
					Context.Log(fmt.Sprintf("DialContext redirect: %s -> %s", origAddr, addr))
				}
			} else if strings.HasPrefix(addr, "appwrite.wladapps.com:") {
				port := strings.Split(addr, ":")[1]
				addr = fmt.Sprintf("%s:%s", targetIP, port)
				Context.Log(fmt.Sprintf("DialContext prefix redirect: %s -> %s", origAddr, addr))
			}
			return dialer.DialContext(ctx, network, addr)
		},
		ForceAttemptHTTP2:   true,
		MaxIdleConns:        100,
		IdleConnTimeout:     90 * time.Second,
		TLSHandshakeTimeout: 10 * time.Second,
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true,
			ServerName:         "appwrite.wladapps.com",
		},
	}

	if clt.Client == nil {
		clt.Client = &http.Client{
			Timeout: clt.Timeout,
		}
	}
	clt.Client.Transport = customTransport
	http.DefaultTransport = customTransport
}

const (
	DatabaseID      = "671f6e1600022832cba5"
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
	configureAppClient(&appClient, Context)

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

		// Decode DocumentList directly to preserve all custom fields in data
		var documents []interface{}
		var listMap map[string]interface{}
		if dErr := res.Decode(&listMap); dErr == nil {
			if docsVal, ok := listMap["documents"].([]interface{}); ok {
				documents = docsVal
			}
		}
		if len(documents) == 0 && len(res.Documents) > 0 {
			for _, doc := range res.Documents {
				var docMap map[string]interface{}
				if dErr := doc.Decode(&docMap); dErr == nil {
					documents = append(documents, docMap)
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
			tipoRecorrencia := strings.TrimSpace(getStringAttribute(recDoc, "tipoRecorrencia"))
			if tipoRecorrencia == "" {
				tipoRecorrencia = "mês" // Default to month
			}
			freq := getIntAttribute(recDoc, "frequencia")
			if freq <= 0 {
				freq = 1
			}

			// 2. Calculate rolling 24-occurrence target horizon from today
			targetHorizon := addRecurrenceInterval(startOfDay, tipoRecorrencia, freq, 24)

			// Fast-path: Check if fimRecorrencia is already recorded and reaches the target horizon
			fimRecorrenciaStr := getStringAttribute(recDoc, "fimRecorrencia")
			if fimDate, ok := parseDateString(fimRecorrenciaStr); ok {
				if !fimDate.Before(targetHorizon) {
					Context.Log(fmt.Sprintf("Recurrence %s buffer is up-to-date until %s (horizon %s). Skipping in O(1).", recID, fimDate.Format("2006-01-02"), targetHorizon.Format("2006-01-02")))
					return
				}
			}

			// Query the latest transactions associated with this recurrence rule
			// Limit to 10 to locate the latest legitimate transaction with valid description
			txRes, err := dbService.ListDocuments(
				DatabaseID,
				TransactionColl,
				dbService.WithListDocumentsQueries([]string{
					query.Equal("recorrencia", recID),
					query.OrderDesc("dataCompetencia"),
					query.Limit(10),
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
			var txListMap map[string]interface{}
			if dErr := txRes.Decode(&txListMap); dErr == nil {
				if docsVal, ok := txListMap["documents"].([]interface{}); ok {
					txDocuments = docsVal
				}
			}
			if len(txDocuments) == 0 && len(txRes.Documents) > 0 {
				for _, doc := range txRes.Documents {
					var docMap map[string]interface{}
					if dErr := doc.Decode(&docMap); dErr == nil {
						txDocuments = append(txDocuments, docMap)
					}
				}
			}

			if len(txDocuments) == 0 {
				Context.Log(fmt.Sprintf("No transactions found for recurrence %s. Skipping.", recID))
				return
			}

			// Find latest valid transaction with non-empty description and valid dataCompetencia
			var latestTx interface{}
			var latestDate time.Time
			for _, cand := range txDocuments {
				desc := strings.TrimSpace(getStringAttribute(cand, "descricao"))
				if desc == "" {
					continue
				}
				d, ok := parseTransactionDate(cand, Context)
				if ok {
					latestTx = cand
					latestDate = d
					break
				}
			}

			if latestTx == nil {
				Context.Log(fmt.Sprintf("Warning: recurrence %s has no transactions with valid description. Skipping to avoid generating invalid data.", recID))
				return
			}

			latestTxID := getDocumentID(latestTx)
			descricao := strings.TrimSpace(getStringAttribute(latestTx, "descricao"))
			if descricao == "" {
				Context.Log(fmt.Sprintf("Warning: latest transaction %s has empty description. Skipping recurrence %s.", latestTxID, recID))
				return
			}

			// If latest transaction already reaches or exceeds target horizon, do NOT create any transactions.
			if !latestDate.Before(targetHorizon) {
				// Save fimRecorrencia checkpoint if missing or outdated so future cron runs skip early
				if fimRecorrenciaStr == "" {
					_, _ = dbService.UpdateDocument(
						DatabaseID,
						RecurrenceColl,
						recID,
						dbService.WithUpdateDocumentData(map[string]interface{}{
							"fimRecorrencia": latestDate.Format(time.RFC3339),
						}),
					)
				}
				Context.Log(fmt.Sprintf("Recurrence %s already has occurrences up to %s (horizon %s). No new transactions needed.", recID, latestDate.Format("2006-01-02"), targetHorizon.Format("2006-01-02")))
				return
			}

			// Fetch divisions of latestTx once to clone them for all newly generated transactions
			divRes, err := dbService.ListDocuments(
				DatabaseID,
				DivisionsColl,
				dbService.WithListDocumentsQueries([]string{
					query.Equal("transacao", latestTxID),
					query.Limit(100),
				}),
			)
			var divDocuments []interface{}
			if err == nil {
				var divListMap map[string]interface{}
				if dErr := divRes.Decode(&divListMap); dErr == nil {
					if docsVal, ok := divListMap["documents"].([]interface{}); ok {
						divDocuments = docsVal
					}
				}
				if len(divDocuments) == 0 && len(divRes.Documents) > 0 {
					for _, doc := range divRes.Documents {
						var docMap map[string]interface{}
						if dErr := doc.Decode(&docMap); dErr == nil {
							divDocuments = append(divDocuments, docMap)
						}
					}
				}
			} else {
				Context.Error(fmt.Sprintf("Warning: error fetching divisions for transaction %s: %v", latestTxID, err))
			}

			// Extract fields to clone from the latest transaction
			valor := getFloatAttribute(latestTx, "valor")
			tipo := strings.TrimSpace(getStringAttribute(latestTx, "tipo"))
			if tipo == "" {
				tipo = "despesa"
			}
			conta := getRelationID(latestTx, "conta")
			contaDestino := getRelationID(latestTx, "contaDestino")
			categoria := getRelationID(latestTx, "categoria")
			devedorContato := getRelationID(latestTx, "devedorContato")
			credorContato := getRelationID(latestTx, "credorContato")

			currentDate := latestDate
			createdForRule := 0
			const maxCreations = 48 // Safety circuit breaker

			for currentDate.Before(targetHorizon) && createdForRule < maxCreations {
				nextDate := addRecurrenceInterval(currentDate, tipoRecorrencia, freq, 1)

				newTxData := map[string]interface{}{
					"descricao":       descricao,
					"valor":           valor,
					"tipo":            tipo,
					"dataCompetencia": nextDate.Format(time.RFC3339),
					"consolidada":     false,
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

				newTx, err := dbService.CreateDocument(
					DatabaseID,
					TransactionColl,
					"unique()",
					newTxData,
				)
				if err != nil {
					Context.Error(fmt.Sprintf("Failed to create new transaction for recurrence %s at %s: %v", recID, nextDate.Format("2006-01-02"), err))
					mu.Lock()
					errorCount++
					mu.Unlock()
					return
				}

				newTxID := getDocumentID(newTx)
				Context.Log(fmt.Sprintf("Cloned transaction %s -> %s with competency date %s", latestTxID, newTxID, nextDate.Format("2006-01-02")))

				// Clone divisions for the new transaction
				for _, divDoc := range divDocuments {
					contatoResponsavel := getRelationID(divDoc, "contatoResponsavel")
					peso := getFloatAttribute(divDoc, "peso")

					newDivData := map[string]interface{}{
						"transacao": newTxID,
						"peso":      peso,
					}
					if contatoResponsavel != "" {
						newDivData["contatoResponsavel"] = contatoResponsavel
					}

					_, divErr := dbService.CreateDocument(
						DatabaseID,
						DivisionsColl,
						"unique()",
						newDivData,
					)
					if divErr != nil {
						Context.Error(fmt.Sprintf("Failed to clone division for transaction %s: %v", newTxID, divErr))
						mu.Lock()
						errorCount++
						mu.Unlock()
					}
				}

				currentDate = nextDate
				createdForRule++
			}

			// Update fimRecorrencia on transacao_recorrencia to currentDate only if new transactions were created
			if createdForRule > 0 {
				_, updateErr := dbService.UpdateDocument(
					DatabaseID,
					RecurrenceColl,
					recID,
					dbService.WithUpdateDocumentData(map[string]interface{}{
						"fimRecorrencia": currentDate.Format(time.RFC3339),
					}),
				)
				if updateErr != nil {
					Context.Error(fmt.Sprintf("Failed to update fimRecorrencia for recurrence %s: %v", recID, updateErr))
				} else {
					Context.Log(fmt.Sprintf("Updated fimRecorrencia checkpoint for %s to %s (created %d installments)", recID, currentDate.Format("2006-01-02"), createdForRule))
				}
			}

			mu.Lock()
			createdCount += createdForRule
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
	if doc == nil {
		return nil
	}

	var flatMap map[string]interface{}
	switch v := doc.(type) {
	case map[string]interface{}:
		flatMap = v
	case *models.Document:
		if err := v.Decode(&flatMap); err != nil {
			docJSON, _ := json.Marshal(v)
			_ = json.Unmarshal(docJSON, &flatMap)
		}
	case models.Document:
		if err := v.Decode(&flatMap); err != nil {
			docJSON, _ := json.Marshal(v)
			_ = json.Unmarshal(docJSON, &flatMap)
		}
	default:
		docJSON, err := json.Marshal(doc)
		if err == nil {
			_ = json.Unmarshal(docJSON, &flatMap)
		}
	}

	if flatMap == nil {
		return nil
	}

	if val, exists := flatMap[key]; exists && val != nil {
		return val
	}

	// Check if nested under "data"
	if dataVal, exists := flatMap["data"]; exists && dataVal != nil {
		if dataMap, ok := dataVal.(map[string]interface{}); ok {
			if val, exists := dataMap[key]; exists && val != nil {
				return val
			}
		}
	}

	return nil
}

func getDocumentID(doc interface{}) string {
	val := getAttribute(doc, "$id")
	if strVal, ok := val.(string); ok && strVal != "" {
		return strVal
	}
	val = getAttribute(doc, "id")
	if strVal, ok := val.(string); ok && strVal != "" {
		return strVal
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
		if len(fields) >= 3 && fields[1] == "00000000" && fields[2] != "00000000" {
			var a, b, c, d int
			if n, err := fmt.Sscanf(fields[2], "%02x%02x%02x%02x", &a, &b, &c, &d); err == nil && n == 4 {
				ip := fmt.Sprintf("%d.%d.%d.%d", d, c, b, a)
				if ip != "0.0.0.0" {
					return ip
				}
			}
		}
	}
	return ""
}

func parseDateString(raw string) (time.Time, bool) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return time.Time{}, false
	}

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
			return t.UTC(), true
		}
	}

	if len(raw) >= 10 {
		if t, err := time.Parse("2006-01-02", raw[:10]); err == nil {
			return t.UTC(), true
		}
	}

	return time.Time{}, false
}

func addRecurrenceInterval(base time.Time, tipo string, freq int, steps int) time.Time {
	switch strings.ToLower(strings.TrimSpace(tipo)) {
	case "dia":
		return base.AddDate(0, 0, steps*freq)
	case "semana":
		return base.AddDate(0, 0, steps*7*freq)
	case "quinzenal", "quinzena":
		return base.AddDate(0, 0, steps*15*freq)
	case "mês", "mes":
		return base.AddDate(0, steps*freq, 0)
	case "ano":
		return base.AddDate(steps*freq, 0, 0)
	default:
		return base.AddDate(0, steps*freq, 0)
	}
}

func parseTransactionDate(doc interface{}, Context openruntimes.Context) (time.Time, bool) {
	raw := getStringAttribute(doc, "dataCompetencia")
	if t, ok := parseDateString(raw); ok {
		return t, true
	}
	return time.Time{}, false
}
