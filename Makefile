# M-Pesa CLI Makefile
# Provides common development and build tasks

.PHONY: help setup build test clean install lint fmt vet deps snapshot release docker

# Variables
APP_NAME := mpesa-cli
VERSION := $(shell git describe --tags --always --dirty)
COMMIT := $(shell git rev-parse --short HEAD)
DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
LDFLAGS := -s -w -X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.date=$(DATE)

# Go parameters
GOCMD := go
GOBUILD := $(GOCMD) build
GOCLEAN := $(GOCMD) clean
GOTEST := $(GOCMD) test
GOGET := $(GOCMD) get
GOMOD := $(GOCMD) mod
GOFMT := gofmt

# Build parameters
BUILD_DIR := dist
BINARY_NAME := $(APP_NAME)
BINARY_UNIX := $(BINARY_NAME)_unix

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@egrep '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Set up development environment
	$(GOMOD) download
	$(GOMOD) verify
	@echo "Installing development tools..."
	$(GOGET) github.com/goreleaser/goreleaser@latest
	$(GOGET) github.com/golangci/golangci-lint/cmd/golangci-lint@latest

deps: ## Download and verify dependencies
	$(GOMOD) download
	$(GOMOD) verify
	$(GOMOD) tidy

build: ## Build the binary for current platform
	mkdir -p $(BUILD_DIR)
	$(GOBUILD) -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME) ./main.go

build-all: ## Build binaries for all platforms
	mkdir -p $(BUILD_DIR)
	# Linux
	GOOS=linux GOARCH=amd64 $(GOBUILD) -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME)_linux_amd64 ./main.go
	GOOS=linux GOARCH=arm64 $(GOBUILD) -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME)_linux_arm64 ./main.go
	# macOS
	GOOS=darwin GOARCH=amd64 $(GOBUILD) -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME)_darwin_amd64 ./main.go
	GOOS=darwin GOARCH=arm64 $(GOBUILD) -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME)_darwin_arm64 ./main.go
	# Windows
	GOOS=windows GOARCH=amd64 $(GOBUILD) -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME)_windows_amd64.exe ./main.go
	GOOS=windows GOARCH=386 $(GOBUILD) -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME)_windows_386.exe ./main.go

test: ## Run tests
	$(GOTEST) -v -race -coverprofile=coverage.out ./...

test-coverage: test ## Run tests and show coverage
	$(GOCMD) tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

lint: ## Run golangci-lint
	golangci-lint run

fmt: ## Format code
	$(GOFMT) -s -w .

vet: ## Run go vet
	$(GOCMD) vet ./...

clean: ## Clean build artifacts
	$(GOCLEAN)
	rm -rf $(BUILD_DIR)
	rm -f coverage.out coverage.html

install: build ## Install binary to $GOPATH/bin
	cp $(BUILD_DIR)/$(BINARY_NAME) $(GOPATH)/bin/

run: ## Run the application
	$(GOCMD) run ./main.go

# Development targets
dev-setup: setup ## Complete development setup
	@echo "Setting up git hooks..."
	@if [ -d .git ]; then \
		echo "#!/bin/sh" > .git/hooks/pre-commit; \
		echo "make fmt lint test" >> .git/hooks/pre-commit; \
		chmod +x .git/hooks/pre-commit; \
		echo "Pre-commit hook installed"; \
	fi

# CI targets
ci: deps lint vet test ## Run CI pipeline locally

# GoReleaser targets
snapshot: ## Build snapshot with GoReleaser (without publishing)
	goreleaser release --snapshot --clean --skip=publish

release: ## Create a release with GoReleaser (requires tag)
	@if [ -z "$(shell git tag --points-at HEAD)" ]; then \
		echo "No tag found for HEAD. Create a tag first: git tag v1.0.0"; \
		exit 1; \
	fi
	goreleaser release --clean

# Docker targets
docker: ## Build Docker image
	docker build -t $(APP_NAME):$(VERSION) .
	docker tag $(APP_NAME):$(VERSION) $(APP_NAME):latest

docker-run: docker ## Build and run Docker image
	docker run --rm $(APP_NAME):$(VERSION) --help

# Security
security-scan: ## Run security scan with gosec
	gosec ./...

# Documentation
docs: ## Generate documentation
	@echo "Generating CLI documentation..."
	@mkdir -p docs
	@$(GOBUILD) -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME) ./main.go
	@$(BUILD_DIR)/$(BINARY_NAME) --help > docs/cli-help.txt
	@echo "Documentation generated in docs/"

# Version info
version: ## Show version information
	@echo "App Name: $(APP_NAME)"
	@echo "Version:  $(VERSION)"
	@echo "Commit:   $(COMMIT)"
	@echo "Date:     $(DATE)"