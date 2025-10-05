package cmd

import (
	"fmt"
	"strings"
	"time"
)

func showSpinner(message string, done chan bool) {
	spinner := []string{"⣟", "⣯", "⣷", "⣾", "⣽", "⣻"}
	i := 0
	for {
		select {
		case <-done:
			fmt.Print("\r" + strings.Repeat(" ", len(message)+2) + "\r")
			close(done)
			return
		default:
			fmt.Printf("\r%s %s ", message, spinner[i])
			i = (i + 1) % len(spinner)
			time.Sleep(100 * time.Millisecond)
		}
	}
}
