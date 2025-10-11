#!/bin/bash

# Installation test script for different package managers
# Usage: ./install-test.sh [homebrew|apt|yum|scoop|docker]

set -e

PACKAGE_MANAGER="$1"
CLI_NAME="mpesa-cli"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

notify_pagerduty() {
    if [[ -n "$PAGERDUTY_INTEGRATION_KEY" ]]; then
        local status="$1"
        local message="$2"
        
        curl -X POST https://events.pagerduty.com/v2/enqueue \
          -H 'Content-Type: application/json' \
          -d "{
            \"routing_key\": \"$PAGERDUTY_INTEGRATION_KEY\",
            \"event_action\": \"trigger\",
            \"payload\": {
              \"summary\": \"M-Pesa CLI $PACKAGE_MANAGER installation $status\",
              \"source\": \"github-actions\",
              \"severity\": \"error\",
              \"custom_details\": {
                \"message\": \"$message\",
                \"package_manager\": \"$PACKAGE_MANAGER\"
              }
            }
          }" > /dev/null 2>&1 || true
    fi
}

test_installation() {
    log_info "Testing $CLI_NAME installation..."
    
    if command -v $CLI_NAME > /dev/null 2>&1; then
        log_info "$CLI_NAME is installed"
        
        # Test basic commands
        log_info "Testing version command..."
        $CLI_NAME --version || {
            log_error "Failed to run --version"
            return 1
        }
        
        log_info "Testing help command..."
        $CLI_NAME --help > /dev/null || {
            log_error "Failed to run --help"
            return 1
        }
        
        log_info "Testing doctor command..."
        $CLI_NAME doctor || {
            log_warn "Doctor command failed (expected if not authenticated)"
        }
        
        log_info "Installation test passed!"
        return 0
    else
        log_error "$CLI_NAME is not installed or not in PATH"
        return 1
    fi
}

case "$PACKAGE_MANAGER" in
    homebrew)
        log_info "Testing Homebrew installation..."
        
        # Add our tap
        brew tap martwebber/tap || {
            log_error "Failed to add Homebrew tap"
            notify_pagerduty "failed" "Failed to add Homebrew tap"
            exit 1
        }
        
        # Install the package
        brew install $CLI_NAME || {
            log_error "Failed to install via Homebrew"
            notify_pagerduty "failed" "Failed to install via Homebrew"
            exit 1
        }
        
        test_installation || {
            notify_pagerduty "failed" "Installation verification failed for Homebrew"
            exit 1
        }
        ;;
        
    apt)
        log_info "Testing APT installation..."
        
        # Update package list
        sudo apt-get update || {
            log_error "Failed to update apt package list"
            notify_pagerduty "failed" "Failed to update apt package list"
            exit 1
        }
        
        # Add our repository (if we have one)
        # For now, we'll test direct .deb installation
        log_info "Testing direct .deb installation..."
        
        # Download latest release
        LATEST_URL=$(curl -s https://api.github.com/repos/martwebber/mpesa-cli/releases/latest | grep -o "https://.*amd64\.deb" | head -1)
        
        if [[ -n "$LATEST_URL" ]]; then
            wget -O /tmp/mpesa-cli.deb "$LATEST_URL" || {
                log_error "Failed to download .deb package"
                notify_pagerduty "failed" "Failed to download .deb package"
                exit 1
            }
            
            sudo dpkg -i /tmp/mpesa-cli.deb || {
                log_error "Failed to install .deb package"
                notify_pagerduty "failed" "Failed to install .deb package"
                exit 1
            }
        else
            log_error "Could not find .deb package URL"
            notify_pagerduty "failed" "Could not find .deb package URL"
            exit 1
        fi
        
        test_installation || {
            notify_pagerduty "failed" "Installation verification failed for APT"
            exit 1
        }
        ;;
        
    yum)
        log_info "Testing YUM installation..."
        
        # Install wget if not available
        yum install -y wget || {
            log_error "Failed to install wget"
            notify_pagerduty "failed" "Failed to install wget"
            exit 1
        }
        
        # Download and install latest RPM
        LATEST_URL=$(curl -s https://api.github.com/repos/martwebber/mpesa-cli/releases/latest | grep -o "https://.*x86_64\.rpm" | head -1)
        
        if [[ -n "$LATEST_URL" ]]; then
            wget -O /tmp/mpesa-cli.rpm "$LATEST_URL" || {
                log_error "Failed to download .rpm package"
                notify_pagerduty "failed" "Failed to download .rpm package"
                exit 1
            }
            
            yum install -y /tmp/mpesa-cli.rpm || {
                log_error "Failed to install .rpm package"
                notify_pagerduty "failed" "Failed to install .rpm package"
                exit 1
            }
        else
            log_error "Could not find .rpm package URL"
            notify_pagerduty "failed" "Could not find .rpm package URL"
            exit 1
        fi
        
        test_installation || {
            notify_pagerduty "failed" "Installation verification failed for YUM"
            exit 1
        }
        ;;
        
    scoop)
        log_info "Testing Scoop installation..."
        
        # Add our bucket
        scoop bucket add martwebber https://github.com/martwebber/scoop-bucket || {
            log_error "Failed to add Scoop bucket"
            notify_pagerduty "failed" "Failed to add Scoop bucket"
            exit 1
        }
        
        # Install the package
        scoop install $CLI_NAME || {
            log_error "Failed to install via Scoop"
            notify_pagerduty "failed" "Failed to install via Scoop"
            exit 1
        }
        
        test_installation || {
            notify_pagerduty "failed" "Installation verification failed for Scoop"
            exit 1
        }
        ;;
        
    docker)
        log_info "Testing Docker installation..."
        
        # Test Docker image from GHCR
        docker run --rm ghcr.io/martwebber/$CLI_NAME:latest --version || {
            log_error "Failed to run Docker image from GHCR"
            notify_pagerduty "failed" "Failed to run Docker image from GHCR"
            exit 1
        }
        
        docker run --rm ghcr.io/martwebber/$CLI_NAME:latest --help > /dev/null || {
            log_error "Failed to run --help in Docker from GHCR"
            notify_pagerduty "failed" "Failed to run --help in Docker from GHCR"
            exit 1
        }
        
        log_info "Docker installation test passed!"
        ;;
        
    *)
        log_error "Unknown package manager: $PACKAGE_MANAGER"
        log_info "Supported package managers: homebrew, apt, yum, scoop, docker"
        exit 1
        ;;
esac

log_info "✅ All tests passed for $PACKAGE_MANAGER!"
exit 0