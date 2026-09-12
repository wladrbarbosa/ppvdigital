package handler

import (
	"strings"
	"testing"
	"time"

	"github.com/open-runtimes/types-for-go/v4/openruntimes"
)

func TestParseDateString(t *testing.T) {
	tests := []struct {
		input    string
		expected string
		valid    bool
	}{
		{"2026-09-11T10:00:00Z", "2026-09-11", true},
		{"2026-09-11T10:00:00.000Z", "2026-09-11", true},
		{"2026-09-11", "2026-09-11", true},
		{"", "", false},
		{"invalid-date", "", false},
	}

	for _, tt := range tests {
		parsed, ok := parseDateString(tt.input)
		if ok != tt.valid {
			t.Errorf("parseDateString(%q) validity = %v, expected %v", tt.input, ok, tt.valid)
		}
		if ok && parsed.Format("2006-01-02") != tt.expected {
			t.Errorf("parseDateString(%q) = %s, expected %s", tt.input, parsed.Format("2006-01-02"), tt.expected)
		}
	}
}

func TestAddRecurrenceInterval(t *testing.T) {
	base := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)

	tests := []struct {
		tipo     string
		freq     int
		steps    int
		expected string
	}{
		{"dia", 1, 5, "2026-01-06"},
		{"dia", 3, 2, "2026-01-07"},
		{"semana", 1, 2, "2026-01-15"},
		{"quinzenal", 1, 2, "2026-01-31"},
		{"mês", 1, 3, "2026-04-01"},
		{"mes", 2, 2, "2026-05-01"},
		{"ano", 1, 1, "2027-01-01"},
	}

	for _, tt := range tests {
		res := addRecurrenceInterval(base, tt.tipo, tt.freq, tt.steps)
		if res.Format("2006-01-02") != tt.expected {
			t.Errorf("addRecurrenceInterval(%s, freq=%d, steps=%d) = %s, expected %s",
				tt.tipo, tt.freq, tt.steps, res.Format("2006-01-02"), tt.expected)
		}
	}
}

func TestAutoHealingBuffer(t *testing.T) {
	// Simulate: base today is 2026-09-11, monthly recurrence (freq=1)
	today := time.Date(2026, 9, 11, 0, 0, 0, 0, time.UTC)
	targetHorizon := addRecurrenceInterval(today, "mês", 1, 24)

	// Suppose existing transactions only reached 20 occurrences ahead:
	latestDate := addRecurrenceInterval(today, "mês", 1, 20)

	// Check that latestDate is before targetHorizon
	if !latestDate.Before(targetHorizon) {
		t.Fatalf("expected latestDate to be before targetHorizon")
	}

	// Run auto-healing loop
	currentDate := latestDate
	createdCount := 0
	for currentDate.Before(targetHorizon) {
		nextDate := addRecurrenceInterval(currentDate, "mês", 1, 1)
		currentDate = nextDate
		createdCount++
	}

	// Exactly 4 missing occurrences should be healed
	if createdCount != 4 {
		t.Errorf("expected 4 created occurrences to heal gap, got %d", createdCount)
	}

	// Check that final currentDate is now not before targetHorizon
	if currentDate.Before(targetHorizon) {
		t.Errorf("expected final currentDate to reach targetHorizon")
	}
}

func TestGetAttribute_DirectAndNested(t *testing.T) {
	// Direct map structure
	directDoc := map[string]interface{}{
		"$id":             "tx123",
		"descricao":       "Salário",
		"valor":           2500.50,
		"frequencia":      1,
		"tipoRecorrencia": "mês",
		"conta":           "conta_abc",
	}

	if getDocumentID(directDoc) != "tx123" {
		t.Errorf("expected doc ID 'tx123', got %s", getDocumentID(directDoc))
	}
	if getStringAttribute(directDoc, "descricao") != "Salário" {
		t.Errorf("expected descricao 'Salário', got %s", getStringAttribute(directDoc, "descricao"))
	}
	if getFloatAttribute(directDoc, "valor") != 2500.50 {
		t.Errorf("expected valor 2500.50, got %f", getFloatAttribute(directDoc, "valor"))
	}
	if getIntAttribute(directDoc, "frequencia") != 1 {
		t.Errorf("expected frequencia 1, got %d", getIntAttribute(directDoc, "frequencia"))
	}
	if getRelationID(directDoc, "conta") != "conta_abc" {
		t.Errorf("expected relation ID 'conta_abc', got %s", getRelationID(directDoc, "conta"))
	}

	// Nested under "data" map (Appwrite JSON format)
	nestedDoc := map[string]interface{}{
		"$id": "tx456",
		"data": map[string]interface{}{
			"descricao":  "Aluguel",
			"valor":      1200.0,
			"frequencia": 2,
			"conta": map[string]interface{}{
				"$id": "conta_nested",
			},
		},
	}

	if getDocumentID(nestedDoc) != "tx456" {
		t.Errorf("expected doc ID 'tx456', got %s", getDocumentID(nestedDoc))
	}
	if getStringAttribute(nestedDoc, "descricao") != "Aluguel" {
		t.Errorf("expected descricao 'Aluguel', got %s", getStringAttribute(nestedDoc, "descricao"))
	}
	if getFloatAttribute(nestedDoc, "valor") != 1200.0 {
		t.Errorf("expected valor 1200.0, got %f", getFloatAttribute(nestedDoc, "valor"))
	}
	if getIntAttribute(nestedDoc, "frequencia") != 2 {
		t.Errorf("expected frequencia 2, got %d", getIntAttribute(nestedDoc, "frequencia"))
	}
	if getRelationID(nestedDoc, "conta") != "conta_nested" {
		t.Errorf("expected relation ID 'conta_nested', got %s", getRelationID(nestedDoc, "conta"))
	}
}

func TestParseTransactionDate_Validation(t *testing.T) {
	dummyCtx := openruntimes.Context{}

	validDoc := map[string]interface{}{
		"$id":             "tx_valid",
		"dataCompetencia": "2028-09-01T00:00:00.000Z",
	}
	parsed, ok := parseTransactionDate(validDoc, dummyCtx)
	if !ok {
		t.Errorf("expected valid date parsing, got false")
	}
	if parsed.Year() != 2028 || parsed.Month() != 9 || parsed.Day() != 1 {
		t.Errorf("unexpected parsed date: %v", parsed)
	}

	emptyDoc := map[string]interface{}{
		"$id":             "tx_empty",
		"dataCompetencia": "",
	}
	_, okEmpty := parseTransactionDate(emptyDoc, dummyCtx)
	if okEmpty {
		t.Errorf("expected parseTransactionDate to fail for empty dataCompetencia, but got true")
	}

	invalidDoc := map[string]interface{}{
		"$id":             "tx_invalid",
		"dataCompetencia": "not-a-date",
	}
	_, okInvalid := parseTransactionDate(invalidDoc, dummyCtx)
	if okInvalid {
		t.Errorf("expected parseTransactionDate to fail for invalid date, but got true")
	}
}

func TestNoOpWhenAlreadyCoversHorizon(t *testing.T) {
	// If latestDate is already >= targetHorizon, 0 transactions should be generated
	now := time.Date(2026, 9, 12, 0, 0, 0, 0, time.UTC)
	targetHorizon := addRecurrenceInterval(now, "mês", 1, 24) // 2028-09-12

	// Suppose existing transactions reach 2028-10-01 (already past targetHorizon)
	latestDate := time.Date(2028, 10, 1, 0, 0, 0, 0, time.UTC)

	if latestDate.Before(targetHorizon) {
		t.Fatalf("expected latestDate to be >= targetHorizon")
	}

	// In the generation logic:
	createdCount := 0
	currentDate := latestDate
	for currentDate.Before(targetHorizon) {
		createdCount++
		currentDate = addRecurrenceInterval(currentDate, "mês", 1, 1)
	}

	if createdCount != 0 {
		t.Errorf("expected 0 created transactions when horizon already covered, got %d", createdCount)
	}
}

func TestEmptyDescriptionValidation(t *testing.T) {
	// Ensure that candidates with empty description are rejected
	candidates := []map[string]interface{}{
		{
			"$id":             "tx_corrupt",
			"descricao":       "",
			"dataCompetencia": "2028-09-01T00:00:00.000Z",
		},
		{
			"$id":             "tx_whitespace",
			"descricao":       "   ",
			"dataCompetencia": "2028-08-01T00:00:00.000Z",
		},
		{
			"$id":             "tx_valid",
			"descricao":       "Assinatura Streaming",
			"dataCompetencia": "2028-07-01T00:00:00.000Z",
		},
	}

	var validTx map[string]interface{}
	dummyCtx := openruntimes.Context{}

	for _, cand := range candidates {
		desc := strings.TrimSpace(getStringAttribute(cand, "descricao"))
		if desc == "" {
			continue
		}
		_, ok := parseTransactionDate(cand, dummyCtx)
		if ok {
			validTx = cand
			break
		}
	}

	if validTx == nil {
		t.Fatalf("expected to find valid transaction")
	}
	if validTx["$id"] != "tx_valid" {
		t.Errorf("expected to pick 'tx_valid', got %v", validTx["$id"])
	}
}
