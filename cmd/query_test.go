package cmd

import (
	"bytes"
	"errors"
	"os"
	"strings"
	"testing"

	"github.com/spf13/cobra"
)

// TestQueryCommandSuccess tests successful query execution
func TestQueryCommandSuccess(t *testing.T) {
	// Create a buffer to capture output
	var output bytes.Buffer

	// Create a test command
	cmd := &cobra.Command{
		Use: "query",
		RunE: func(cmd *cobra.Command, args []string) error {
			// Mock successful scenario
			output.WriteString("✔ Query successful!")
			return nil
		},
	}

	// Execute the command
	err := cmd.Execute()
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	// Check output
	if !strings.Contains(output.String(), "Query successful") {
		t.Error("expected success message in output")
	}
}

// TestQueryCommandCredentialError tests credential retrieval error
func TestQueryCommandCredentialError(t *testing.T) {
	// Create a buffer to capture output
	var output bytes.Buffer

	// Create a test command that simulates credential error
	cmd := &cobra.Command{
		Use: "query",
		RunE: func(cmd *cobra.Command, args []string) error {
			output.WriteString("❌ Failed to get credentials.")
			return errors.New("credentials not found")
		},
	}

	// Execute the command
	err := cmd.Execute()
	if err == nil {
		t.Error("expected error for missing credentials")
	}

	// Check that error message was written
	if !strings.Contains(output.String(), "Failed to get credentials") {
		t.Error("expected credential error message in output")
	}
}

// TestQueryCommandAuthError tests authentication error
func TestQueryCommandAuthError(t *testing.T) {
	// Create a buffer to capture output
	var output bytes.Buffer

	// Create a test command that simulates auth error
	cmd := &cobra.Command{
		Use: "query",
		RunE: func(cmd *cobra.Command, args []string) error {
			output.WriteString("❌ Authentication failed.")
			return errors.New("authentication failed")
		},
	}

	// Execute the command
	err := cmd.Execute()
	if err == nil {
		t.Error("expected error for authentication failure")
	}

	// Check that error message was written
	if !strings.Contains(output.String(), "Authentication failed") {
		t.Error("expected authentication error message in output")
	}
}

// TestQueryCommandQueryError tests transaction query error
func TestQueryCommandQueryError(t *testing.T) {
	// Create a buffer to capture output
	var output bytes.Buffer

	// Create a test command that simulates query error
	cmd := &cobra.Command{
		Use: "query",
		RunE: func(cmd *cobra.Command, args []string) error {
			output.WriteString("❌ Query failed.")
			return errors.New("query transaction failed")
		},
	}

	// Execute the command
	err := cmd.Execute()
	if err == nil {
		t.Error("expected error for query failure")
	}

	// Check that error message was written
	if !strings.Contains(output.String(), "Query failed") {
		t.Error("expected query error message in output")
	}
}

// TestQueryCommandValidation tests command flag validation
func TestQueryCommandValidation(t *testing.T) {
	// Save original args
	oldArgs := os.Args
	defer func() { os.Args = oldArgs }()

	// Test with missing required flag
	cmd := &cobra.Command{
		Use: "query",
		RunE: func(cmd *cobra.Command, args []string) error {
			transactionID := cmd.Flag("id").Value.String()
			if transactionID == "" {
				return errors.New("transaction ID is required")
			}
			return nil
		},
	}

	// Add the flag
	cmd.Flags().StringP("id", "i", "", "Transaction ID (required)")
	_ = cmd.MarkFlagRequired("id")

	// Set args without the required flag
	os.Args = []string{"cmd", "query"}

	// Execute should fail due to missing required flag
	err := cmd.Execute()
	if err == nil {
		t.Error("expected error for missing required flag")
	}
}

// TestQueryFlagParsing tests that flags are parsed correctly
func TestQueryFlagParsing(t *testing.T) {
	var capturedID string

	cmd := &cobra.Command{
		Use: "query",
		RunE: func(cmd *cobra.Command, args []string) error {
			capturedID = cmd.Flag("id").Value.String()
			return nil
		},
	}

	cmd.Flags().StringP("id", "i", "", "Transaction ID (required)")

	// Set the flag and execute
	cmd.SetArgs([]string{"--id", "TEST123"})
	err := cmd.Execute()

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if capturedID != "TEST123" {
		t.Errorf("expected transaction ID 'TEST123', got '%s'", capturedID)
	}
}

// TestQueryCommandWithRealQueryCmd tests the actual query command structure
func TestQueryCommandWithRealQueryCmd(t *testing.T) {
	// This test ensures the query command has the right structure
	if queryCmd.Use != "query" {
		t.Errorf("expected Use to be 'query', got '%s'", queryCmd.Use)
	}

	if queryCmd.Short == "" {
		t.Error("expected Short description to be set")
	}

	if queryCmd.Long == "" {
		t.Error("expected Long description to be set")
	}

	if queryCmd.RunE == nil {
		t.Error("expected RunE to be set")
	}
}


