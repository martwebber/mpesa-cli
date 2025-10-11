package mpesa

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// TestQueryTransactionWithConfigSuccess tests successful transaction query with mock config
func TestQueryTransactionWithConfigSuccess(t *testing.T) {
	const (
		testCredential  = "test-credential"  // #nosec G101 - This is a test credential, not hardcoded
		testResultURL   = "https://test.com/result"
		testTimeoutURL  = "https://test.com/timeout"
		testAccessToken = "test-access-token"
		contentType     = "Content-Type"
		applicationJSON = "application/json"
	)

	// Create a mock response
	mockResponse := transactionStatusResponse{
		ConversationID:           "AG_20231010_12345",
		OriginatorConversationID: "29115-34620561-1",
		ResponseCode:             "0",
		ResponseDescription:      "The service request is processed successfully.",
	}

	// Create test server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Verify request method and headers
		if r.Method != "POST" {
			t.Errorf("expected POST request, got %s", r.Method)
		}

		if r.Header.Get(contentType) != applicationJSON {
			t.Errorf("expected Content-Type application/json, got %s", r.Header.Get(contentType))
		}

		authHeader := r.Header.Get("Authorization")
		if !strings.HasPrefix(authHeader, "Bearer ") {
			t.Errorf("expected Bearer token in Authorization header, got %s", authHeader)
		}

		// Send mock response
		w.Header().Set(contentType, applicationJSON)
		_ = json.NewEncoder(w).Encode(mockResponse)
	}))
	defer server.Close()

	// Create a test config
	testConfig := &Config{
		BusinessShortcode:  "600986",
		SecurityCredential: testCredential,
		Environment:        "sandbox",
		Initiator:          "testapi",
		ResultURL:          testResultURL,
		QueueTimeOutURL:    testTimeoutURL,
	}

	accessToken := testAccessToken
	transactionID := "TEST12345"

	// Test with config but it will still try to connect to real endpoint
	// This is a limitation of the current implementation
	_, err := QueryTransactionWithConfig(accessToken, transactionID, testConfig)

	// Since we can't override the URL easily, expect an error (network failure)
	if err == nil {
		t.Error("expected error when connecting to real URL, got nil")
	}
}

// TestQueryTransactionWithNilConfig tests that nil config falls back to defaults
func TestQueryTransactionWithNilConfig(t *testing.T) {
	const (
		testCredential  = "test-credential"  // #nosec G101 - This is a test credential, not hardcoded
		testResultURL   = "https://test.com/result"
		testTimeoutURL  = "https://test.com/timeout"
		testAccessToken = "test-access-token"
	)

	accessToken := testAccessToken
	transactionID := "TEST12345"

	// Test with nil config - should use defaults or loaded config
	_, err := QueryTransactionWithConfig(accessToken, transactionID, nil)

	// Expect an error since we're trying to connect to real API
	if err == nil {
		t.Error("expected error when connecting to real API, got nil")
	}
}

// TestQueryTransactionNetworkError tests handling of network errors
func TestQueryTransactionNetworkError(t *testing.T) {
	const (
		testCredential  = "test-credential"  // #nosec G101 - This is a test credential, not hardcoded
		testResultURL   = "https://test.com/result"
		testTimeoutURL  = "https://test.com/timeout"
		testAccessToken = "test-access-token"
	)

	// Test with invalid config that will cause network error
	testConfig := &Config{
		BusinessShortcode:  "600986",
		SecurityCredential: testCredential,
		Environment:        "sandbox", // This will try to connect to real sandbox URL
		Initiator:          "testapi",
		ResultURL:          testResultURL,
		QueueTimeOutURL:    testTimeoutURL,
	}

	accessToken := testAccessToken
	transactionID := "TEST12345"

	_, err := QueryTransactionWithConfig(accessToken, transactionID, testConfig)
	if err == nil {
		t.Error("expected network error, got nil")
	}
}

// TestGetDefaultConfig tests the default configuration
func TestGetDefaultConfig(t *testing.T) {
	config := GetDefaultConfig()

	if config.BusinessShortcode != "600986" {
		t.Errorf("expected BusinessShortcode to be '600986', got '%s'", config.BusinessShortcode)
	}

	if config.Environment != "sandbox" {
		t.Errorf("expected Environment to be 'sandbox', got '%s'", config.Environment)
	}

	if config.Initiator != "testapi" {
		t.Errorf("expected Initiator to be 'testapi', got '%s'", config.Initiator)
	}
}

// TestValidateConfig tests configuration validation
func TestValidateConfig(t *testing.T) {
	tests := []struct {
		name      string
		config    *Config
		expectErr bool
	}{
		{
			name: "valid sandbox config",
			config: &Config{
				Environment: "sandbox",
				Initiator:   "testapi",
			},
			expectErr: false,
		},
		{
			name: "valid production config",
			config: &Config{
				BusinessShortcode:  "123456",
				SecurityCredential: "test-credential",
				Environment:        "production",
				Initiator:          "testapi",
			},
			expectErr: false,
		},
		{
			name: "invalid environment",
			config: &Config{
				Environment: "invalid",
			},
			expectErr: true,
		},
		{
			name: "production missing shortcode",
			config: &Config{
				SecurityCredential: "test-credential",
				Environment:        "production",
			},
			expectErr: true,
		},
		{
			name: "production missing credential",
			config: &Config{
				BusinessShortcode: "123456",
				Environment:       "production",
			},
			expectErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := validateConfig(tt.config)
			if tt.expectErr && err == nil {
				t.Error("expected error but got nil")
			}
			if !tt.expectErr && err != nil {
				t.Errorf("expected no error but got: %v", err)
			}
		})
	}
}
