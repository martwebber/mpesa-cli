package cmd

import (
	"fmt"
	"strings"
	"syscall"

	"github.com/martwebber/mpesa-cli/pkg/mpesa"

	"github.com/spf13/cobra"
	"golang.org/x/term"
)

var loginCmd = &cobra.Command{
	Use:   "login",
	Short: "Authenticate with the M-Pesa API",
	Long: `The login command securely prompts for your M-Pesa Consumer Key
and Consumer Secret, validates them, and stores them in your system's keychain.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		fmt.Println("First, please enter your credentials from the Daraja Portal.")

		fmt.Print("? Consumer Key: ")
		var consumerKey string
		_, _ = fmt.Scanln(&consumerKey)
		consumerKey = strings.TrimSpace(consumerKey)

		// Validate consumer key
		if consumerKey == "" {
			fmt.Println("❌ Consumer Key cannot be empty")
			return fmt.Errorf("consumer key cannot be empty")
		}

		fmt.Print("? Consumer Secret: ")
		byteSecret, err := term.ReadPassword(int(syscall.Stdin))
		if err != nil {
			return fmt.Errorf("failed to read secret: %w", err)
		}
		consumerSecret := strings.TrimSpace(string(byteSecret))
		fmt.Println()

		// Validate consumer secret
		if consumerSecret == "" {
			fmt.Println("❌ Consumer Secret cannot be empty")
			return fmt.Errorf("consumer secret cannot be empty")
		}

		done := make(chan bool)
		go showSpinner("Authenticating with M-Pesa...", done)

		_, err = mpesa.GetAccessToken(consumerKey, consumerSecret)
		done <- true
		<-done

		if err != nil {
			fmt.Println("\n❌ Authentication failed.")
			return fmt.Errorf("authentication failed: %w", err)
		}

		fmt.Println("\n✔ Authentication successful!")

		err = mpesa.SetCredentials(consumerKey, consumerSecret)
		if err != nil {
			return fmt.Errorf("failed to store credentials: %w", err)
		}

		fmt.Println("✅ Your credentials have been securely stored.")
		fmt.Println("💡 Tip: Run `mpesa doctor` to check your connection.")

		return nil
	},
}

func init() {
	rootCmd.AddCommand(loginCmd)
}
