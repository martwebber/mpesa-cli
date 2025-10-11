package mpesa

import (
	"fmt"
	"os"

	"github.com/spf13/viper"
)

// Config holds configuration for M-Pesa API operations
type Config struct {
	// BusinessShortcode is your organization's shortcode (Paybill or Buygoods - A 5 to 7 digit account number)
	BusinessShortcode string `mapstructure:"business_shortcode"`

	// SecurityCredential is the encrypted credential of the user getting transaction details
	SecurityCredential string `mapstructure:"security_credential"`

	// Environment specifies which M-Pesa environment to use: "sandbox" or "production"
	Environment string `mapstructure:"environment"`

	// Initiator is the name of Initiator to initiating the request
	Initiator string `mapstructure:"initiator"`

	// ResultURL is the path that stores information of transaction
	ResultURL string `mapstructure:"result_url"`

	// QueueTimeOutURL is the path that stores information of time out transaction
	QueueTimeOutURL string `mapstructure:"queue_timeout_url"`
}

// GetConfig returns the current configuration, loading from file and environment variables
func GetConfig() (*Config, error) {
	// Set defaults
	viper.SetDefault("environment", "sandbox")
	viper.SetDefault("initiator", "testapi")
	viper.SetDefault("result_url", "https://domain.com/result")
	viper.SetDefault("queue_timeout_url", "https://domain.com/timeout")

	// Try to read config file
	viper.SetConfigName("mpesa-cli")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("$HOME/.config/mpesa-cli")
	viper.AddConfigPath("/etc/mpesa-cli")

	// Read environment variables
	viper.AutomaticEnv()
	viper.SetEnvPrefix("MPESA")

	// Bind environment variables explicitly for underscore handling
	_ = viper.BindEnv("environment")
	_ = viper.BindEnv("business_shortcode")
	_ = viper.BindEnv("security_credential")
	_ = viper.BindEnv("initiator")
	_ = viper.BindEnv("result_url")
	_ = viper.BindEnv("queue_timeout_url")

	// Read config file if it exists (don't error if it doesn't)
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("failed to read config file: %w", err)
		}
	}

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	// Validate required fields
	if err := validateConfig(&config); err != nil {
		return nil, err
	}

	return &config, nil
}

// validateConfig ensures required configuration values are set
func validateConfig(config *Config) error {
	if config.Environment != "sandbox" && config.Environment != "production" {
		return fmt.Errorf("environment must be either 'sandbox' or 'production', got: %s", config.Environment)
	}

	// For production, we need these values
	if config.Environment == "production" {
		if config.BusinessShortcode == "" {
			return fmt.Errorf("business_shortcode is required for production environment")
		}
		if config.SecurityCredential == "" {
			return fmt.Errorf("security_credential is required for production environment")
		}
	}

	return nil
}

// GetDefaultConfig returns a default configuration for sandbox testing
func GetDefaultConfig() *Config {
	return &Config{
		BusinessShortcode:  "600986",                 // Default sandbox shortcode
		SecurityCredential: "YourSecurityCredential", // Placeholder for sandbox
		Environment:        "sandbox",
		Initiator:          "testapi",
		ResultURL:          "https://domain.com/result",
		QueueTimeOutURL:    "https://domain.com/timeout",
	}
}

// SaveConfigTemplate creates a sample configuration file
func SaveConfigTemplate(filepath string) error {
	configTemplate := `# M-Pesa CLI Configuration File
# Copy this file to ~/.config/mpesa-cli/mpesa-cli.yaml and customize

# Your M-Pesa environment: "sandbox" or "production"
environment: sandbox

# Your business shortcode (required for production)
# business_shortcode: "123456"

# Your security credential (required for production)  
# security_credential: "your-encrypted-credential"

# API initiator name (optional, defaults to "testapi")
# initiator: "your-initiator-name"

# Callback URLs for transaction results (optional)
# result_url: "https://yourdomain.com/mpesa/result"
# queue_timeout_url: "https://yourdomain.com/mpesa/timeout"
`

	return os.WriteFile(filepath, []byte(configTemplate), 0600)
}
