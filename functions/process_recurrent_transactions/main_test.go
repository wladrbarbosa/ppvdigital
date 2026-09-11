package handler

import (
	"testing"
	"time"
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
