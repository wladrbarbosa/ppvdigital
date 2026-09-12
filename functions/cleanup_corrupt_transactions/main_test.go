package handler

import (
	"encoding/json"
	"net/http"
	"testing"

	"github.com/appwrite/sdk-for-go/v5/appwrite"
	"github.com/open-runtimes/types-for-go/v4/openruntimes"
)

func TestCleanupRequestDefaults(t *testing.T) {
	rawJSON := `{"dryRun": true, "concurrency": 10}`
	req := CleanupRequest{
		DryRun:        false,
		EmptyDescOnly: true,
		Concurrency:   20,
		Reconcile:     true,
	}

	err := json.Unmarshal([]byte(rawJSON), &req)
	if err != nil {
		t.Fatalf("unexpected unmarshal error: %v", err)
	}

	if !req.DryRun {
		t.Errorf("expected dryRun to be true")
	}
	if !req.EmptyDescOnly {
		t.Errorf("expected emptyDescOnly default to be true")
	}
	if req.Concurrency != 10 {
		t.Errorf("expected concurrency 10, got %d", req.Concurrency)
	}
	if !req.Reconcile {
		t.Errorf("expected reconcile default to be true")
	}
}

func TestGetAttributeInCleanup(t *testing.T) {
	doc := map[string]interface{}{
		"$id": "doc_123",
		"data": map[string]interface{}{
			"descricao": "Teste Transacao",
			"peso":      1.0,
		},
	}

	if getDocumentID(doc) != "doc_123" {
		t.Errorf("expected doc_123, got %s", getDocumentID(doc))
	}
	if getStringAttribute(doc, "descricao") != "Teste Transacao" {
		t.Errorf("expected 'Teste Transacao', got %s", getStringAttribute(doc, "descricao"))
	}
}

func TestConfigureAppClient(t *testing.T) {
	fakeCtx := openruntimes.Context{}
	appClient := appwrite.NewClient(
		appwrite.WithEndpoint("https://appwrite.wladapps.com/v1"),
		appwrite.WithProject("test_project"),
		appwrite.WithKey("test_key"),
	)

	configureAppClient(&appClient, fakeCtx)

	if appClient.Client == nil {
		t.Fatal("expected appClient.Client to not be nil")
	}
	if appClient.Client.Transport == nil {
		t.Fatal("expected appClient.Client.Transport to be set")
	}
	transport, ok := appClient.Client.Transport.(*http.Transport)
	if !ok {
		t.Fatalf("expected *http.Transport, got %T", appClient.Client.Transport)
	}
	if transport.TLSClientConfig == nil {
		t.Fatal("expected TLSClientConfig to be configured")
	}
	if !transport.TLSClientConfig.InsecureSkipVerify {
		t.Errorf("expected InsecureSkipVerify to be true")
	}
	if transport.TLSClientConfig.ServerName != "appwrite.wladapps.com" {
		t.Errorf("expected ServerName to be appwrite.wladapps.com, got %s", transport.TLSClientConfig.ServerName)
	}
}

func TestGetDefaultGateway(t *testing.T) {
	gw := getDefaultGateway()
	if gw == "0.0.0.0" {
		t.Errorf("getDefaultGateway should never return 0.0.0.0")
	}
}

