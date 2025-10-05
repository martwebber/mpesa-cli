package cmd

import (
	"errors"
	"fmt"
	"strings"
	"testing"
)

// --- Mocks ---var loginCmd = &cobra.Command{

var (
	mockCredsOK    = func() (string, string, error) { return "key", "secret", nil }
	mockCredsError = func() (string, string, error) { return "", "", errors.New("no creds") }
	mockTokenOK    = func(url, key, secret string) error { return nil }
	mockTokenError = func(url, key, secret string) error { return errors.New("bad creds") }
)

func TestDoctorCheckCredentialsMissing(t *testing.T) {
	var output []string
	doctorCheck(
		mockCredsError,
		mockTokenOK,
		func(args ...interface{}) { output = append(output, sprint(args...)) },
	)
	found := false
	for _, line := range output {
		if strings.Contains(line, "Credentials not found") {
			found = true
		}
	}
	if !found {
		t.Error("expected credentials not found message")
	}
}

func TestDoctorCheckTokenFailures(t *testing.T) {
	var output []string
	doctorCheck(
		mockCredsOK,
		mockTokenError,
		func(args ...interface{}) { output = append(output, sprint(args...)) },
	)
	sandboxFail, prodFail := false, false
	for _, line := range output {
		if strings.Contains(line, "Sandbox environment: Failed") {
			sandboxFail = true
		}
		if strings.Contains(line, "Production environment: Failed") {
			prodFail = true
		}
	}
	if !sandboxFail || !prodFail {
		t.Error("expected both sandbox and production failures")
	}
}

func TestDoctorCheckAllOK(t *testing.T) {
	var output []string
	doctorCheck(
		mockCredsOK,
		mockTokenOK,
		func(args ...interface{}) { output = append(output, sprint(args...)) },
	)
	ok := false
	for _, line := range output {
		if strings.Contains(line, "Auth token fetched successfully") {
			ok = true
		}
	}
	if !ok {
		t.Error("expected success message")
	}
}

// sprint joins args like fmt.Sprint but returns a string
func sprint(args ...interface{}) string {
	var sb strings.Builder
	for i, a := range args {
		if i > 0 {
			sb.WriteRune(' ')
		}
		sb.WriteString(strings.TrimSpace(strings.ReplaceAll(strings.Trim(fmt.Sprintf("%v", a), "\n"), "\n", " ")))
	}
	return sb.String()
}
