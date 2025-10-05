package cmd

import (
	"fmt"
	"log"
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
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("First, please enter your credentials from the Daraja Portal.")

		fmt.Print("? Consumer Key: ")
		var consumerKey string
		fmt.Scanln(&consumerKey)
		consumerKey = strings.TrimSpace(consumerKey)

		fmt.Print("? Consumer Secret: ")
		byteSecret, err := term.ReadPassword(int(syscall.Stdin))
		if err != nil {
			log.Fatalf("Failed to read secret: %v", err)
		}
		consumerSecret := strings.TrimSpace(string(byteSecret))
		fmt.Println()

		done := make(chan bool)
		go showSpinner("Authenticating with M-Pesa...", done)

		_, err = mpesa.GetAccessToken(consumerKey, consumerSecret)
		done <- true
		<-done

		if err != nil {
			fmt.Println("\n❌ Authentication failed.")
			log.Fatalf("Error: %v", err)
		}

		fmt.Println("\n✔ Authentication successful!")

		err = mpesa.SetCredentials(consumerKey, consumerSecret)
		if err != nil {
			log.Fatalf("Failed to store credentials: %v", err)
		}

		fmt.Println("✅ Your credentials have been securely stored.")
		fmt.Println("💡 Tip: Run `mpesa doctor` to check your connection.")
	},
}

func init() {
	rootCmd.AddCommand(loginCmd)
}
