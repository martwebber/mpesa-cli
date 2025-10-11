/*
Copyright © 2025 NAME HERE mwangi.martin24@gmail.com
*/
package cmd

import (
	"os"

	"github.com/spf13/cobra"
)

// completionCmd represents the completion command
var completionCmd = &cobra.Command{
	Use:   "completion [bash|zsh|fish|powershell]",
	Short: "Generate completion script",
	Long: `To load completions:

Bash:

  $ source <(mpesa-cli completion bash)

  # To load completions for each session, execute once:
  # Linux:
  $ mpesa-cli completion bash > /etc/bash_completion.d/mpesa-cli
  # macOS:
  $ mpesa-cli completion bash > /usr/local/etc/bash_completion.d/mpesa-cli

Zsh:

  # If shell completion is not already enabled in your environment,
  # you will need to enable it.  You can execute the following once:

  $ echo "autoload -U compinit; compinit" >> ~/.zshrc

  # To load completions for each session, execute once:
  $ mpesa-cli completion zsh > "${fpath[1]}/_mpesa-cli"

  # You will need to start a new shell for this setup to take effect.

Fish:

  $ mpesa-cli completion fish | source

  # To load completions for each session, execute once:
  $ mpesa-cli completion fish > ~/.config/fish/completions/mpesa-cli.fish

PowerShell:

  PS> mpesa-cli completion powershell | Out-String | Invoke-Expression

  # To load completions for every new session, run:
  PS> mpesa-cli completion powershell > mpesa-cli.ps1
  # and source this file from your PowerShell profile.
`,
	DisableFlagsInUseLine: true,
	ValidArgs:             []string{"bash", "zsh", "fish", "powershell"},
	Args:                  cobra.MatchAll(cobra.ExactArgs(1), cobra.OnlyValidArgs),
	RunE: func(cmd *cobra.Command, args []string) error {
		switch args[0] {
		case "bash":
			return cmd.Root().GenBashCompletion(os.Stdout)
		case "zsh":
			return cmd.Root().GenZshCompletion(os.Stdout)
		case "fish":
			return cmd.Root().GenFishCompletion(os.Stdout, true)
		case "powershell":
			return cmd.Root().GenPowerShellCompletionWithDesc(os.Stdout)
		default:
			return nil
		}
	},
}

func init() {
	rootCmd.AddCommand(completionCmd)
}
