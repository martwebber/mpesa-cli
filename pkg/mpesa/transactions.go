package mpesa

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// transactionStatusRequest represents the JSON payload sent to the M-Pesa Transaction Status API.
// This struct contains all the required fields for querying the status of a transaction.
type transactionStatusRequest struct {
	// Initiator is the name of the user initiating the request
	Initiator string `json:"Initiator"`

	// SecurityCredential is the encrypted credential of the user getting transaction details
	SecurityCredential string `json:"SecurityCredential"`

	// CommandID specifies the type of transaction whose status is being queried
	CommandID string `json:"CommandID"`

	// TransactionID is the unique identifier of the transaction being queried
	TransactionID string `json:"TransactionID"`

	// PartyA is the organization's shortcode (Paybill or Buygoods)
	PartyA string `json:"PartyA"`

	// IdentifierType specifies the type of organization receiving the transaction
	IdentifierType string `json:"IdentifierType"`

	// ResultURL is the path that stores information of the transaction
	ResultURL string `json:"ResultURL"`

	// QueueTimeOutURL is the path that stores information of time out transaction
	QueueTimeOutURL string `json:"QueueTimeOutURL"`

	// Remarks are additional information for the transaction
	Remarks string `json:"Remarks"`

	// Occasion is any additional information to be associated with the transaction
	Occasion string `json:"Occasion"`
}

// transactionStatusResponse represents the JSON response from the M-Pesa Transaction Status API.
// This struct contains the response details including status codes and conversation IDs.
type transactionStatusResponse struct {
	// ConversationID is the unique identifier of the conversation for this transaction
	ConversationID string `json:"ConversationID"`

	// OriginatorConversationID is the unique identifier of the conversation from the originator
	OriginatorConversationID string `json:"OriginatorConversationID"`

	// ResponseCode indicates the status of the request (0 for success)
	ResponseCode string `json:"ResponseCode"`

	// ResponseDescription provides a human-readable description of the response
	ResponseDescription string `json:"ResponseDescription"`
}

// QueryTransaction sends a request to the M-Pesa transaction status API.
// It queries the status of a specific M-Pesa transaction using the transaction ID.
// Returns the transaction status response or an error if the query fails.
func QueryTransaction(accessToken, transactionID string) (*transactionStatusResponse, error) {
	return QueryTransactionWithConfig(accessToken, transactionID, nil)
}

// QueryTransactionWithConfig sends a request to the M-Pesa transaction status API using the provided config.
// If config is nil, it will load the config from file/environment or use defaults.
func QueryTransactionWithConfig(accessToken, transactionID string, config *Config) (*transactionStatusResponse, error) {
	if config == nil {
		var err error
		config, err = GetConfig()
		if err != nil {
			// Fall back to default config for backward compatibility
			config = GetDefaultConfig()
		}
	}

	reqBody := transactionStatusRequest{
		Initiator:          config.Initiator,
		SecurityCredential: config.SecurityCredential,
		CommandID:          "TransactionStatusQuery",
		TransactionID:      transactionID,
		PartyA:             config.BusinessShortcode,
		IdentifierType:     "4",
		ResultURL:          config.ResultURL,
		QueueTimeOutURL:    config.QueueTimeOutURL,
		Remarks:            "Status Check",
		Occasion:           "Verification",
	}

	// Convert the request body struct to a JSON byte slice
	jsonBody, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("error marshalling request body: %w", err)
	}

	// Use appropriate URL based on environment
	var url string
	if config.Environment == "production" {
		url = "https://api.safaricom.co.ke/mpesa/transactionstatus/v1/query"
	} else {
		url = "https://sandbox.safaricom.co.ke/mpesa/transactionstatus/v1/query"
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBody))
	if err != nil {
		return nil, fmt.Errorf("error creating request: %w", err)
	}

	// Set the required headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+accessToken)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("error sending request: %w", err)
	}
	defer func() { _ = resp.Body.Close() }()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("error reading response body: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("api request failed with status %d: %s", resp.StatusCode, string(respBody))
	}

	var result transactionStatusResponse
	if err := json.Unmarshal(respBody, &result); err != nil {
		return nil, fmt.Errorf("failed to parse transaction status response: %w", err)
	}

	return &result, nil
}
