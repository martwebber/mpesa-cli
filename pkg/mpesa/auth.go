package mpesa

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/zalando/go-keyring"
)

const serviceName = "mpesa-cli"

// authResponse holds the response from the M-Pesa OAuth API
type authResponse struct {
	AccessToken string `json:"access_token"`
	ExpiresIn   string `json:"expires_in"`
}

// AuthURL is the M-Pesa OAuth endpoint URL (can be modified for testing)
var AuthURL = "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"

// GetAccessToken authenticates with the M-Pesa API using consumer credentials.
// It sends a request to the M-Pesa OAuth endpoint and returns an access token
// that can be used for subsequent API calls. The token is valid for the duration
// specified in the ExpiresIn field of the response.
//
// Parameters:
//   - consumerKey: The consumer key from the Daraja portal
//   - consumerSecret: The consumer secret from the Daraja portal
//
// Returns:
//   - string: The access token for API authentication
//   - error: Any error that occurred during authentication
func GetAccessToken(consumerKey, consumerSecret string) (string, error) {
	req, err := http.NewRequest("GET", AuthURL, nil)
	if err != nil {
		return "", err
	}

	auth := base64.StdEncoding.EncodeToString([]byte(consumerKey + ":" + consumerSecret))
	req.Header.Set("Authorization", "Basic "+auth)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("authentication failed with status %d: %s", resp.StatusCode, string(body))
	}

	var result authResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return "", fmt.Errorf("failed to parse auth response: %v", err)
	}

	return result.AccessToken, nil
}

// SetCredentials securely stores the M-Pesa consumer key and secret in the system keychain.
// The credentials are encrypted and stored using the operating system's native
// keychain/credential manager (Keychain on macOS, Credential Manager on Windows,
// Secret Service on Linux).
//
// Parameters:
//   - consumerKey: The consumer key to store
//   - consumerSecret: The consumer secret to store
//
// Returns:
//   - error: Any error that occurred during storage
func SetCredentials(consumerKey, consumerSecret string) error {
	err := keyring.Set(serviceName, "consumer_key", consumerKey)
	if err != nil {
		return fmt.Errorf("failed to store consumer key in keychain: %w", err)
	}

	err = keyring.Set(serviceName, "consumer_secret", consumerSecret)
	if err != nil {
		return fmt.Errorf("failed to store consumer secret in keychain: %w", err)
	}

	return nil
}

// GetCredentials retrieves the M-Pesa consumer key and secret from the system keychain.
// The credentials must have been previously stored using SetCredentials.
//
// Returns:
//   - string: The consumer key
//   - string: The consumer secret
//   - error: Any error that occurred during retrieval, including if credentials are not found
func GetCredentials() (string, string, error) {
	consumerKey, err := keyring.Get(serviceName, "consumer_key")
	if err != nil {
		return "", "", fmt.Errorf("could not retrieve consumer key. Please run 'mpesa-cli login' again: %w", err)
	}

	consumerSecret, err := keyring.Get(serviceName, "consumer_secret")
	if err != nil {
		return "", "", fmt.Errorf("could not retrieve consumer secret. Please run 'mpesa-cli login' again: %w", err)
	}

	return consumerKey, consumerSecret, nil
}
