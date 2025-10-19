#!/bin/bash

# Auto-update script for M-Pesa CLI
# This script automatically detects and installs the latest version

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_header() {
    echo -e "${BLUE}$1${NC}"
}

# Function to get the latest version from GitHub
get_latest_version() {
    curl -s https://api.github.com/repos/martwebber/mpesa-cli/releases/latest | \
    grep '"tag_name":' | \
    sed -E 's/.*"([^"]+)".*/\1/'
}

# Function to get current installed version
get_current_version() {
    if command -v mpesa-cli >/dev/null 2>&1; then
        mpesa-cli --version 2>/dev/null | head -n1 | cut -d' ' -f3 || echo "unknown"
    else
        echo "none"
    fi
}

# Function to detect OS and architecture
detect_system() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case $OS in
        linux) OS="linux" ;;
        darwin) OS="darwin" ;;
        *) log_error "Unsupported OS: $OS"; exit 1 ;;
    esac
    
    case $ARCH in
        x86_64) ARCH="x86_64" ;;
        amd64) ARCH="x86_64" ;;
        aarch64) ARCH="arm64" ;;
        arm64) ARCH="arm64" ;;
        armv7l) ARCH="armv7" ;;
        armv6l) ARCH="armv6" ;;
        i386|i686) ARCH="i386" ;;
        *) log_error "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    
    log_info "Detected system: $OS/$ARCH"
}

# Function to install via package manager (preferred)
install_via_package_manager() {
    log_header "🔄 Attempting installation via package managers..."
    
    # Try Homebrew first (works on macOS and Linux)
    if command -v brew >/dev/null 2>&1; then
        log_info "Using Homebrew..."
        if brew tap | grep -q "martwebber/tap"; then
            brew upgrade martwebber/tap/mpesa-cli
        else
            brew tap martwebber/tap
            brew install mpesa-cli
        fi
        return 0
    fi
    
    # Try APT (Debian/Ubuntu)
    if command -v apt-get >/dev/null 2>&1 && [ "$OS" = "linux" ]; then
        log_info "Downloading .deb package..."
        LATEST_VERSION=$(get_latest_version)
        DEB_URL="https://github.com/martwebber/mpesa-cli/releases/download/${LATEST_VERSION}/mpesa-cli_${LATEST_VERSION#v}_linux_amd64.deb"
        
        wget -O "/tmp/mpesa-cli.deb" "$DEB_URL"
        sudo dpkg -i "/tmp/mpesa-cli.deb"
        rm "/tmp/mpesa-cli.deb"
        return 0
    fi
    
    # Try YUM/DNF (RHEL/CentOS/Fedora)
    if (command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1) && [ "$OS" = "linux" ]; then
        log_info "Downloading .rpm package..."
        LATEST_VERSION=$(get_latest_version)
        RPM_URL="https://github.com/martwebber/mpesa-cli/releases/download/${LATEST_VERSION}/mpesa-cli_${LATEST_VERSION#v}_linux_x86_64.rpm"
        
        wget -O "/tmp/mpesa-cli.rpm" "$RPM_URL"
        if command -v dnf >/dev/null 2>&1; then
            sudo dnf install "/tmp/mpesa-cli.rpm"
        else
            sudo yum install "/tmp/mpesa-cli.rpm"
        fi
        rm "/tmp/mpesa-cli.rpm"
        return 0
    fi
    
    return 1
}

# Function to install binary directly
install_binary_directly() {
    log_header "📥 Installing binary directly..."
    
    LATEST_VERSION=$(get_latest_version)
    
    # Construct download URL
    if [ "$OS" = "darwin" ]; then
        OS_NAME="Darwin"
    else
        OS_NAME="Linux"
    fi
    
    BINARY_URL="https://github.com/martwebber/mpesa-cli/releases/download/${LATEST_VERSION}/mpesa-cli_${OS_NAME}_${ARCH}.tar.gz"
    
    log_info "Downloading from: $BINARY_URL"
    
    # Download and extract
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"
    
    curl -L -o mpesa-cli.tar.gz "$BINARY_URL"
    tar -xzf mpesa-cli.tar.gz
    
    # Install binary
    if [ -w "/usr/local/bin" ]; then
        cp mpesa-cli /usr/local/bin/mpesa-cli
        chmod +x /usr/local/bin/mpesa-cli
        log_info "Installed to /usr/local/bin/mpesa-cli"
    else
        sudo cp mpesa-cli /usr/local/bin/mpesa-cli
        sudo chmod +x /usr/local/bin/mpesa-cli
        log_info "Installed to /usr/local/bin/mpesa-cli (with sudo)"
    fi
    
    # Install completions if possible
    if [ -d completions ]; then
        if [ -d "/etc/bash_completion.d" ]; then
            sudo cp completions/mpesa-cli.bash /etc/bash_completion.d/mpesa-cli 2>/dev/null || true
        fi
        if [ -d "/usr/share/zsh/site-functions" ]; then
            sudo cp completions/mpesa-cli.zsh /usr/share/zsh/site-functions/_mpesa-cli 2>/dev/null || true
        fi
        if [ -d "/usr/share/fish/completions" ]; then
            sudo cp completions/mpesa-cli.fish /usr/share/fish/completions/mpesa-cli.fish 2>/dev/null || true
        fi
    fi
    
    # Cleanup
    cd - >/dev/null
    rm -rf "$TMP_DIR"
}

# Main function
main() {
    log_header "🚀 M-Pesa CLI Auto-Updater"
    echo
    
    detect_system
    
    CURRENT_VERSION=$(get_current_version)
    LATEST_VERSION=$(get_latest_version)
    
    log_info "Current version: $CURRENT_VERSION"
    log_info "Latest version: $LATEST_VERSION"
    
    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
        log_info "✅ You already have the latest version!"
        exit 0
    fi
    
    if [ "$CURRENT_VERSION" != "none" ]; then
        log_warn "Upgrading from $CURRENT_VERSION to $LATEST_VERSION"
    else
        log_info "Installing M-Pesa CLI $LATEST_VERSION"
    fi
    
    echo
    
    # Try package manager first, fall back to direct binary install
    if install_via_package_manager; then
        log_info "✅ Installation via package manager successful!"
    else
        log_warn "Package managers not available, installing binary directly..."
        install_binary_directly
        log_info "✅ Direct binary installation successful!"
    fi
    
    echo
    
    # Verify installation
    NEW_VERSION=$(get_current_version)
    log_info "Verification: mpesa-cli --version"
    mpesa-cli --version
    
    echo
    log_info "🎉 M-Pesa CLI has been successfully updated to $NEW_VERSION!"
    echo
    log_info "📖 Usage examples:"
    echo "  mpesa-cli login                    # Configure credentials"
    echo "  mpesa-cli transactions query --id TX123  # Query transaction"
    echo "  mpesa-cli doctor                   # Health check"
    echo "  mpesa-cli completion bash          # Generate shell completions"
}

# Run main function
main "$@"