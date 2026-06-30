package handler

import (
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/appwrite/sdk-for-go/v5/appwrite"
	"github.com/open-runtimes/types-for-go/v4/openruntimes"
)

const (
	DatabaseID     = "671f6e1600022832cba5"
	TransactionColl = "671f7a6f000cb3ab17b9"
	RecurrenceColl  = "transacao_recorrencia"
	DivisionsColl   = "divisao_transacoes"
)

func Main(Context openruntimes.Context) openruntimes.Response {
	// Initialize Appwrite Client using Dynamic API Keys & Endpoint guidelines
	appwriteEndpoint := os.Getenv("APPWRITE_FUNCTION_API_ENDPOINT")
	if appwriteEndpoint == "" {
		appwriteEndpoint = os.Getenv("APPWRITE_ENDPOINT")
	}
	if appwriteEndpoint == "" {
		appwriteEndpoint = "https://cloud.appwrite.io/v1"
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
	)

	dbService := appwrite.NewDatabases(appClient)

	Context.Log("Starting generation of infinite recurring transactions (v5 SDK)...")

	// 1. Fetch all recurrent rules where totalParcelas is null (indefinite recurrence)
	var recurrences []interface{}
	cursor := ""
	for {
		queries := []string{
			"isNull(\"totalParcelas\")",
			"limit(100)",
		}
		if cursor != "" {
			queries = append(queries, fmt.Sprintf("cursorAfter(\"%s\")", cursor))
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

	// 2. Process each recurrence rule
	for _, recDoc := range recurrences {
		recID := getDocumentID(recDoc)
		tipoRecorrencia := getStringAttribute(recDoc, "tipoRecorrencia")
		if tipoRecorrencia == "" {
			tipoRecorrencia = "mês" // Default to month
		}
		freq := getIntAttribute(recDoc, "frequencia")
		if freq <= 0 {
			freq = 1
		}

		// Query the latest transaction associated with this recurrence rule
		txRes, err := dbService.ListDocuments(
			DatabaseID,
			TransactionColl,
			dbService.WithListDocumentsQueries([]string{
				fmt.Sprintf("equal(\"recorrencia\", [\"%s\"])", recID),
				"orderDesc(\"dataCompetencia\")",
				"limit(1)",
			}),
		)
		if err != nil {
			Context.Error(fmt.Sprintf("Error fetching latest transaction for recurrence %s: %v", recID, err))
			errorCount++
			continue
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
			continue
		}

		latestTx := txDocuments[0]
		latestTxID := getDocumentID(latestTx)
		dataCompetenciaStr := getStringAttribute(latestTx, "dataCompetencia")

		latestDate, err := time.Parse(time.RFC3339, dataCompetenciaStr)
		if err != nil {
			// Try without offset if standard RFC3339 fails (e.g. custom layout)
			latestDate, err = time.Parse("2006-01-02T15:04:05.000Z07:00", dataCompetenciaStr)
			if err != nil {
				Context.Error(fmt.Sprintf("Error parsing competency date '%s' for transaction %s: %v", dataCompetenciaStr, latestTxID, err))
				errorCount++
				continue
			}
		}

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
			errorCount++
			continue
		}

		newTxID := getDocumentID(newTx)
		Context.Log(fmt.Sprintf("Cloned transaction %s to %s with competency date %s", latestTxID, newTxID, nextDate.Format("2006-01-02")))

		// 3. Clone division of transactions if any exist for the latest transaction
		divRes, err := dbService.ListDocuments(
			DatabaseID,
			DivisionsColl,
			dbService.WithListDocumentsQueries([]string{
				fmt.Sprintf("equal(\"transacao\", [\"%s\"])", latestTxID),
			}),
		)
		if err != nil {
			Context.Error(fmt.Sprintf("Error fetching divisions for transaction %s: %v", latestTxID, err))
			errorCount++
			continue
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

		createdCount++
	}

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
