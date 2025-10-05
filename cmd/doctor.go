
package cmd

import (
	"fmt"

	"github.com/martwebber/mpesa-cli/pkg/mpesa"
	"github.com/spf13/cobra"
)

// doctorCmd represents the doctor command

// doctorCheck runs the health check logic with injectable dependencies for testability.
func doctorCheck(
	getCreds func() (string, string, error),
	getToken func(url, key, secret string) error,
	print func(...interface{}),
) {
	print("🔎 Running M-Pesa CLI Environment Health Check...")

	// 1. Check credentials in keychain
	consumerKey, consumerSecret, err := getCreds()
	if err != nil {
		print("❌ Credentials not found in keychain:", err)
		return
	}
	print("✅ Credentials found in keychain.")

	// 2. Try to fetch auth token for sandbox
	sandboxURL := "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
	if err := getToken(sandboxURL, consumerKey, consumerSecret); err != nil {
		print("❌ Sandbox environment: Failed to fetch auth token:", err)
	} else {
		print("✅ Sandbox environment: Auth token fetched successfully.")
	}

	// 3. Try to fetch auth token for production
	prodURL := "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
	if err := getToken(prodURL, consumerKey, consumerSecret); err != nil {
		print("❌ Production environment: Failed to fetch auth token:", err)
	} else {
		print("✅ Production environment: Auth token fetched successfully.")
	}

	print("\nHealth check complete.")
}

var doctorCmd = &cobra.Command{
	Use:   "doctor",
	Short: "Run environment and credential health checks",
	Long:  `Performs diagnostic checks on your configuration and credentials for both sandbox and production environments.`,
	Run: func(cmd *cobra.Command, args []string) {
		doctorCheck(
			mpesa.GetCredentials,
			func(url, key, secret string) error {
				// Temporarily set AuthURL for each call
				oldURL := mpesa.AuthURL
				mpesa.AuthURL = url
				defer func() { mpesa.AuthURL = oldURL }()
				_, err := mpesa.GetAccessToken(key, secret)
				return err
			},
			func(args ...interface{}) { fmt.Println(args...) },
		)
	},
}

func init() {
	rootCmd.AddCommand(doctorCmd)
}
