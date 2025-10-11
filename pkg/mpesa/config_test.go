package mpesa

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/spf13/viper"
)

// TestSaveConfigTemplate tests config template generation
func TestSaveConfigTemplate(t *testing.T) {
	// Create temporary file
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "test-config.yaml")

	// Save config template
	err := SaveConfigTemplate(configPath)
	if err != nil {
		t.Fatalf("failed to save config template: %v", err)
	}

	// Read the file back
	content, err := os.ReadFile(configPath)
	if err != nil {
		t.Fatalf("failed to read config file: %v", err)
	}

	// Check that it contains expected content
	configStr := string(content)
	if !strings.Contains(configStr, "environment: sandbox") {
		t.Error("expected default environment to be sandbox")
	}

	if !strings.Contains(configStr, "# business_shortcode:") {
		t.Error("expected commented business_shortcode field")
	}

	if !strings.Contains(configStr, "# security_credential:") {
		t.Error("expected commented security_credential field")
	}
}

// TestGetConfigWithDefaults tests configuration loading with defaults
func TestGetConfigWithDefaults(t *testing.T) {
	// Clear viper state
	viper.Reset()

	// Create temporary directory for config
	tmpDir := t.TempDir()

	// Set up viper to look in our temp directory
	viper.AddConfigPath(tmpDir)
	viper.SetConfigName("mpesa-cli")
	viper.SetConfigType("yaml")

	// Create a minimal config file
	configContent := `environment: sandbox`
	configPath := filepath.Join(tmpDir, "mpesa-cli.yaml")
	err := os.WriteFile(configPath, []byte(configContent), 0644)
	if err != nil {
		t.Fatalf("failed to write config file: %v", err)
	}

	config, err := GetConfig()
	if err != nil {
		t.Fatalf("failed to get config: %v", err)
	}

	// Check defaults are applied
	if config.Environment != "sandbox" {
		t.Errorf("expected environment 'sandbox', got '%s'", config.Environment)
	}

	if config.Initiator != "testapi" {
		t.Errorf("expected default initiator 'testapi', got '%s'", config.Initiator)
	}

	if config.ResultURL != "https://domain.com/result" {
		t.Errorf("expected default result URL, got '%s'", config.ResultURL)
	}
}

// TestGetConfigFromEnvVars tests configuration from environment variables
func TestGetConfigFromEnvVars(t *testing.T) {
	// Use sandbox environment for this test to avoid validation issues
	const testCredential = "test-credential"

	// Clear viper state and environment variables first
	viper.Reset()
	os.Unsetenv("MPESA_ENVIRONMENT")
	os.Unsetenv("MPESA_BUSINESS_SHORTCODE")
	os.Unsetenv("MPESA_SECURITY_CREDENTIAL")

	// Set environment variables for a valid sandbox config (simpler validation)
	os.Setenv("MPESA_ENVIRONMENT", "sandbox")
	os.Setenv("MPESA_BUSINESS_SHORTCODE", "123456")
	os.Setenv("MPESA_SECURITY_CREDENTIAL", testCredential)

	// Clean up environment variables after test
	defer func() {
		os.Unsetenv("MPESA_ENVIRONMENT")
		os.Unsetenv("MPESA_BUSINESS_SHORTCODE")
		os.Unsetenv("MPESA_SECURITY_CREDENTIAL")
	}()

	config, err := GetConfig()
	if err != nil {
		t.Fatalf("failed to get config: %v", err)
	}

	if config.Environment != "sandbox" {
		t.Errorf("expected environment 'sandbox', got '%s'", config.Environment)
	}

	if config.BusinessShortcode != "123456" {
		t.Errorf("expected business shortcode '123456', got '%s'", config.BusinessShortcode)
	}

	if config.SecurityCredential != testCredential {
		t.Errorf("expected security credential '%s', got '%s'", testCredential, config.SecurityCredential)
	}
}

// TestGetConfigValidationErrors tests configuration validation
func TestGetConfigValidationErrors(t *testing.T) {
	tests := []struct {
		name        string
		envVars     map[string]string
		expectError bool
		errorText   string
	}{
		{
			name: "invalid environment",
			envVars: map[string]string{
				"MPESA_ENVIRONMENT": "invalid",
			},
			expectError: true,
			errorText:   "environment must be either 'sandbox' or 'production'",
		},
		{
			name: "production missing shortcode",
			envVars: map[string]string{
				"MPESA_ENVIRONMENT":         "production",
				"MPESA_SECURITY_CREDENTIAL": "test-credential",
			},
			expectError: true,
			errorText:   "business_shortcode is required for production environment",
		},
		{
			name: "production missing credential",
			envVars: map[string]string{
				"MPESA_ENVIRONMENT":        "production",
				"MPESA_BUSINESS_SHORTCODE": "123456",
				// Missing MPESA_SECURITY_CREDENTIAL
			},
			expectError: true,
			errorText:   "security_credential is required for production environment",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Clear viper state and all environment variables first
			viper.Reset()
			os.Unsetenv("MPESA_ENVIRONMENT")
			os.Unsetenv("MPESA_BUSINESS_SHORTCODE")
			os.Unsetenv("MPESA_SECURITY_CREDENTIAL")

			// Set environment variables for this test
			for key, value := range tt.envVars {
				os.Setenv(key, value)
			}

			// Clean up environment variables after test
			defer func() {
				os.Unsetenv("MPESA_ENVIRONMENT")
				os.Unsetenv("MPESA_BUSINESS_SHORTCODE")
				os.Unsetenv("MPESA_SECURITY_CREDENTIAL")
			}()

			_, err := GetConfig()
			validateTestError(t, err, tt.expectError, tt.errorText)
		})
	}
}

func validateTestError(t *testing.T, err error, expectError bool, errorText string) {
	if expectError {
		if err == nil {
			t.Error("expected error but got nil")
		} else if !strings.Contains(err.Error(), errorText) {
			t.Errorf("expected error containing '%s', got '%s'", errorText, err.Error())
		}
	} else {
		if err != nil {
			t.Errorf("expected no error but got: %v", err)
		}
	}
}
