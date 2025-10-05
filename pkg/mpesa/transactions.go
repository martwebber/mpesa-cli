package mpesa

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// transactionStatusRequest represents the JSON body we send to the API
type transactionStatusRequest struct {
	Initiator          string `json:"Initiator"`
	SecurityCredential string `json:"SecurityCredential"`
	CommandID          string `json:"CommandID"`
	TransactionID      string `json:"TransactionID"`
	PartyA             string `json:"PartyA"`
	IdentifierType     string `json:"IdentifierType"`
	ResultURL          string `json:"ResultURL"`
	QueueTimeOutURL    string `json:"QueueTimeOutURL"`
	Remarks            string `json:"Remarks"`
	Occasion           string `json:"Occasion"`
}

// transactionStatusResponse represents the JSON response we get from the API
type transactionStatusResponse struct {
	ConversationID           string `json:"ConversationID"`
	OriginatorConversationID string `json:"OriginatorConversationID"`
	ResponseCode             string `json:"ResponseCode"`
	ResponseDescription      string `json:"ResponseDescription"`
}

// QueryTransaction sends a request to the M-Pesa transaction status API
func QueryTransaction(accessToken, transactionID string) (*transactionStatusResponse, error) {
	// TODO: Handle hardcoded values
	reqBody := transactionStatusRequest{
		Initiator:          "testapi",
		SecurityCredential: "YourSecurityCredential", // TODO: This needs to be generated.
		CommandID:          "TransactionStatusQuery",
		TransactionID:      transactionID,
		PartyA:             "600986", // TODO: Your business shortcode
		IdentifierType:     "4",
		ResultURL:          "https://domain.com/result",
		QueueTimeOutURL:    "https://domain.com/timeout",
		Remarks:            "Status Check",
		Occasion:           "Verification",
	}

	// Convert the request body struct to a JSON byte slice
	jsonBody, err := json.Marshal(reqBody)
	if err!= nil {
		return nil, fmt.Errorf("error marshalling request body: %w", err)
	}

	url := "https://sandbox.safaricom.co.ke/mpesa/transactionstatus/v1/query"
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBody))
	if err!= nil {
		return nil, fmt.Errorf("error creating request: %w", err)
	}

	// Set the required headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+accessToken)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err!= nil {
		return nil, fmt.Errorf("error sending request: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err!= nil {
		return nil, fmt.Errorf("error reading response body: %w", err)
	}

	if resp.StatusCode!= http.StatusOK {
		return nil, fmt.Errorf("api request failed with status %d: %s", resp.StatusCode, string(respBody))
	}

	var result transactionStatusResponse
	if err := json.Unmarshal(respBody, &result); err!= nil {
		return nil, fmt.Errorf("failed to parse transaction status response: %w", err)
	}

	return &result, nil
}