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

// A struct to hold the response from the M-Pesa auth API
type authResponse struct {
	AccessToken string `json:"access_token"`
	ExpiresIn   string `json:"expires_in"`
}

var AuthURL = "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"

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

// SetCredentials stores the consumer key and secret in the system keychain.
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

// GetCredentials retrieves the consumer key and secret from the system keychain.
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
