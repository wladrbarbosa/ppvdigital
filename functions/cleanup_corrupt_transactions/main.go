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
	"sync/atomic"
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

type CleanupRequest struct {
	DryRun        bool   `json:"dryRun"`
	EmptyDescOnly bool   `json:"emptyDescOnly"`
	RecurrenceID  string `json:"recurrenceId"`
	Concurrency   int    `json:"concurrency"`
	Reconcile     bool   `json:"reconcile"`
}

func Main(Context openruntimes.Context) openruntimes.Response {
	appwriteEndpoint := os.Getenv("APPWRITE_ENDPOINT")
	if appwriteEndpoint == "" {
		appwriteEndpoint = os.Getenv("APPWRITE_FUNCTION_API_ENDPOINT")
	}
	if appwriteEndpoint == "" || strings.Contains(appwriteEndpoint, "appwrite.wladapps.com") || appwriteEndpoint == "http://appwrite/v1" {
		appwriteEndpoint = "https://appwrite.wladapps.com/v1"
	}
	projectID := os.Getenv("APPWRITE_FUNCTION_PROJECT_ID")
	if projectID == "" {
		projectID = os.Getenv("APPWRITE_PROJECT_ID")
	}

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

	// Parse payload options
	reqOptions := CleanupRequest{
		DryRun:        false,
		EmptyDescOnly: true,
		Concurrency:   20,
		Reconcile:     true,
	}

	_ = Context.Req.BodyJson(&reqOptions)

	if reqOptions.Concurrency <= 0 {
		reqOptions.Concurrency = 20
	}
	if reqOptions.Concurrency > 50 {
		reqOptions.Concurrency = 50
	}

	appClient := appwrite.NewClient(
		appwrite.WithEndpoint(appwriteEndpoint),
		appwrite.WithProject(projectID),
		appwrite.WithKey(apiKey),
		appwrite.WithSelfSigned(true),
	)
	configureAppClient(&appClient, Context)

	dbService := appwrite.NewDatabases(appClient)
	Context.Log(fmt.Sprintf("Starting cleanup execution (DryRun=%v, EmptyDescOnly=%v, Concurrency=%d)...", reqOptions.DryRun, reqOptions.EmptyDescOnly, reqOptions.Concurrency))

	// Phase 1: Search transactions to delete
	var toDeleteIDs []string
	cursor := ""

	for {
		queries := []string{
			query.Limit(100),
		}
		if reqOptions.EmptyDescOnly {
			queries = append(queries, query.Equal("descricao", ""))
		}
		if reqOptions.RecurrenceID != "" {
			queries = append(queries, query.Equal("recorrencia", reqOptions.RecurrenceID))
		}
		if cursor != "" {
			queries = append(queries, query.CursorAfter(cursor))
		}

		res, err := dbService.ListDocuments(
			DatabaseID,
			TransactionColl,
			dbService.WithListDocumentsQueries(queries),
		)
		if err != nil {
			Context.Error(fmt.Sprintf("Error listing transactions: %v", err))
			return Context.Res.Json(map[string]interface{}{
				"success": false,
				"error":   err.Error(),
			})
		}

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
			id := getDocumentID(doc)
			if id != "" {
				toDeleteIDs = append(toDeleteIDs, id)
			}
		}

		cursor = getDocumentID(documents[len(documents)-1])
	}

	Context.Log(fmt.Sprintf("Identified %d transactions matching cleanup criteria.", len(toDeleteIDs)))

	var deletedTxCount int64
	var failedTxCount int64

	if len(toDeleteIDs) > 0 && !reqOptions.DryRun {
		jobs := make(chan string, len(toDeleteIDs))
		for _, id := range toDeleteIDs {
			jobs <- id
		}
		close(jobs)

		var wg sync.WaitGroup
		for i := 0; i < reqOptions.Concurrency; i++ {
			wg.Add(1)
			go func() {
				defer wg.Done()
				for id := range jobs {
					_, err := dbService.DeleteDocument(DatabaseID, TransactionColl, id)
					if err != nil && !strings.Contains(err.Error(), "not found") {
						atomic.AddInt64(&failedTxCount, 1)
					} else {
						atomic.AddInt64(&deletedTxCount, 1)
					}
				}
			}()
		}
		wg.Wait()
		Context.Log(fmt.Sprintf("Deleted transactions: %d (Failed: %d)", deletedTxCount, failedTxCount))
	}

	// Phase 2: Check and clean orphaned divisions (peso == 0)
	var deletedDivCount int64
	cursor = ""
	for {
		queries := []string{
			query.Limit(100),
			query.Equal("peso", 0),
		}
		if cursor != "" {
			queries = append(queries, query.CursorAfter(cursor))
		}

		divRes, err := dbService.ListDocuments(
			DatabaseID,
			DivisionsColl,
			dbService.WithListDocumentsQueries(queries),
		)
		if err != nil {
			break
		}

		var divDocs []interface{}
		var divListMap map[string]interface{}
		if dErr := divRes.Decode(&divListMap); dErr == nil {
			if docsVal, ok := divListMap["documents"].([]interface{}); ok {
				divDocs = docsVal
			}
		}
		if len(divDocs) == 0 && len(divRes.Documents) > 0 {
			for _, doc := range divRes.Documents {
				var docMap map[string]interface{}
				if dErr := doc.Decode(&docMap); dErr == nil {
					divDocs = append(divDocs, docMap)
				}
			}
		}

		if len(divDocs) == 0 {
			break
		}

		for _, doc := range divDocs {
			id := getDocumentID(doc)
			if id != "" {
				if !reqOptions.DryRun {
					_, dErr := dbService.DeleteDocument(DatabaseID, DivisionsColl, id)
					if dErr == nil {
						deletedDivCount++
					}
				} else {
					deletedDivCount++
				}
			}
		}

		cursor = getDocumentID(divDocs[len(divDocs)-1])
	}
	Context.Log(fmt.Sprintf("Cleaned up orphaned divisions with peso 0: %d", deletedDivCount))

	// Phase 3: Reconcile fimRecorrencia in transacao_recorrencia
	reconciledCheckpoints := 0
	if reqOptions.Reconcile {
		cursor = ""
		var recDocs []interface{}
		for {
			queries := []string{
				query.IsNull("totalParcelas"),
				query.Limit(100),
			}
			if cursor != "" {
				queries = append(queries, query.CursorAfter(cursor))
			}

			recRes, err := dbService.ListDocuments(
				DatabaseID,
				RecurrenceColl,
				dbService.WithListDocumentsQueries(queries),
			)
			if err != nil {
				break
			}

			var documents []interface{}
			var listMap map[string]interface{}
			if dErr := recRes.Decode(&listMap); dErr == nil {
				if docsVal, ok := listMap["documents"].([]interface{}); ok {
					documents = docsVal
				}
			}
			if len(documents) == 0 && len(recRes.Documents) > 0 {
				for _, doc := range recRes.Documents {
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
				recDocs = append(recDocs, doc)
			}

			cursor = getDocumentID(documents[len(documents)-1])
		}

		for _, rec := range recDocs {
			recID := getDocumentID(rec)

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
				continue
			}

			var txDocs []interface{}
			var txListMap map[string]interface{}
			if dErr := txRes.Decode(&txListMap); dErr == nil {
				if docsVal, ok := txListMap["documents"].([]interface{}); ok {
					txDocs = docsVal
				}
			}
			if len(txDocs) == 0 && len(txRes.Documents) > 0 {
				for _, doc := range txRes.Documents {
					var docMap map[string]interface{}
					if dErr := doc.Decode(&docMap); dErr == nil {
						txDocs = append(txDocs, docMap)
					}
				}
			}

			var latestValidDate string
			for _, t := range txDocs {
				desc := strings.TrimSpace(getStringAttribute(t, "descricao"))
				dataComp := strings.TrimSpace(getStringAttribute(t, "dataCompetencia"))
				if desc != "" && dataComp != "" {
					latestValidDate = dataComp
					break
				}
			}

			updateData := map[string]interface{}{}
			if latestValidDate != "" {
				updateData["fimRecorrencia"] = latestValidDate
			} else {
				updateData["fimRecorrencia"] = nil
			}

			if !reqOptions.DryRun {
				_, updateErr := dbService.UpdateDocument(
					DatabaseID,
					RecurrenceColl,
					recID,
					dbService.WithUpdateDocumentData(updateData),
				)
				if updateErr == nil {
					reconciledCheckpoints++
				}
			} else {
				reconciledCheckpoints++
			}
		}
		Context.Log(fmt.Sprintf("Reconciled recurrence checkpoints: %d", reconciledCheckpoints))
	}

	return Context.Res.Json(map[string]interface{}{
		"success":               true,
		"dryRun":                reqOptions.DryRun,
		"deletedTransactions":   deletedTxCount,
		"failedTransactions":    failedTxCount,
		"deletedDivisions":      deletedDivCount,
		"reconciledCheckpoints": reconciledCheckpoints,
	})
}

// Utility Helper Functions

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
