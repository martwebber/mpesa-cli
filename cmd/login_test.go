package cmd

import (
	"encoding/base64"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/martwebber/mpesa-cli/pkg/mpesa"
)

// --- Mock auth API success response ---
func TestGetAccessTokenSuccess(t *testing.T) {
	mockToken := "mock-access-token"
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		auth := r.Header.Get("Authorization")
		expected := "Basic " + base64.StdEncoding.EncodeToString([]byte("key:secret"))
		if auth != expected {
			http.Error(w, "invalid credentials", http.StatusUnauthorized)
			return
		}
		resp := map[string]string{
			"access_token": mockToken,
			"expires_in":   "3600",
		}
		json.NewEncoder(w).Encode(resp)
	}))
	defer server.Close()

	// Override API URL dynamically for testing
	oldURL := mpesa.AuthURL
	mpesa.AuthURL = server.URL
	defer func() { mpesa.AuthURL = oldURL }()

	token, err := mpesa.GetAccessToken("key", "secret")
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if token != mockToken {
		t.Fatalf("expected token %q, got %q", mockToken, token)
	}
}

// --- Mock auth API failure ---
func TestGetAccessTokenFailure(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
	}))
	defer server.Close()

	oldURL := mpesa.AuthURL
	mpesa.AuthURL = server.URL
	defer func() { mpesa.AuthURL = oldURL }()

	_, err := mpesa.GetAccessToken("bad", "creds")
	if err == nil {
		t.Fatal("expected error, got nil")
	}
	if !strings.Contains(err.Error(), "authentication failed") {
		t.Fatalf("unexpected error message: %v", err)
	}
}

// --- Spinner test ---
func TestShowSpinnerStopsCleanly(t *testing.T) {
	done := make(chan bool)
	go func() {
		time.Sleep(250 * time.Millisecond)
		done <- true
	}()
	showSpinner("Testing spinner...", done)
	// if it reaches here, spinner exited without hanging
}
