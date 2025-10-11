/*
Copyright © 2025 Martin Mwangi <mwangi.martin24@gmail.com>
*/
package main

import (
	"fmt"
	"os"

	"github.com/martwebber/mpesa-cli/cmd"
)

// Version information (set by goreleaser)
var (
	version = "dev"
	commit  = "unknown"
	date    = "unknown"
)

func main() {
	// Set version info for cobra commands
	cmd.SetVersionInfo(version, commit, date)

	// Handle version flag manually for better output
	if len(os.Args) > 1 && (os.Args[1] == "--version" || os.Args[1] == "-v") {
		fmt.Printf("mpesa-cli version %s\n", version)
		fmt.Printf("Built from commit %s on %s\n", commit, date)
		os.Exit(0)
	}

	cmd.Execute()
}
