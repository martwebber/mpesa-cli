package cmd

import (
	"github.com/spf13/cobra"
)

// transactionsCmd represents the transactions parent command
var transactionsCmd = &cobra.Command{
	Use:   "transactions",
	Short: "Manage M-Pesa transactions",
	Long:  `Parent command for all transaction-related operations.`,
}

func init() {
	rootCmd.AddCommand(transactionsCmd)
}
