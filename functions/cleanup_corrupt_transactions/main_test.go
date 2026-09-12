package handler

import (
	"encoding/json"
	"testing"
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
