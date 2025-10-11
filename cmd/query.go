package cmd

import (
	"fmt"

	"github.com/martwebber/mpesa-cli/pkg/mpesa"
	"github.com/spf13/cobra"
)

var transactionID string

var queryCmd = &cobra.Command{
	Use:   "query",
	Short: "Query the status of an M-Pesa transaction",
	Long:  `Query the status of a specific M-Pesa transaction by providing its ID.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		done := make(chan bool)
		go showSpinner(fmt.Sprintf("Querying status for transaction ID: %s", transactionID), done)

		consumerKey, consumerSecret, err := mpesa.GetCredentials()
		if err != nil {
			done <- true
			<-done
			fmt.Println("\n❌ Failed to get credentials.")
			return fmt.Errorf("error getting credentials: %w", err)
		}

		accessToken, err := mpesa.GetAccessToken(consumerKey, consumerSecret)
		if err != nil {
			done <- true
			<-done
			fmt.Println("\n❌ Authentication failed.")
			return fmt.Errorf("error getting access token: %w", err)
		}

		status, err := mpesa.QueryTransaction(accessToken, transactionID)
		done <- true
		<-done

		if err != nil {
			fmt.Println("\n❌ Query failed.")
			return fmt.Errorf("error querying transaction: %w", err)
		}

		fmt.Println("\n✔ Query successful!")
		fmt.Println("--------------------")
		fmt.Printf("Response Code: %s\n", status.ResponseCode)
		fmt.Printf("Description: %s\n", status.ResponseDescription)
		fmt.Printf("Conversation ID: %s\n", status.ConversationID)
		fmt.Println("--------------------")

		return nil
	},
}

func init() {
	transactionsCmd.AddCommand(queryCmd)
	queryCmd.Flags().StringVarP(&transactionID, "id", "i", "", "The ID of the transaction to query (required)")
	queryCmd.MarkFlagRequired("id")
}
