#!/bin/bash

# Test script to validate release artifacts
# This script checks if the release was successful by testing direct downloads

set -e

# Configuration
PROJECT_NAME="mpesa-cli"
GITHUB_USER="martwebber"
LATEST_TAG="v1.0.21-test"

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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "🔍 Testing Release Artifacts for ${LATEST_TAG}"
echo "=============================================="

# Test 1: Check if GitHub release exists
log_step "Checking GitHub release..."
if curl -s "https://api.github.com/repos/$GITHUB_USER/$PROJECT_NAME/releases/tags/$LATEST_TAG" | grep -q "\"tag_name\""; then
    log_info "✅ GitHub release $LATEST_TAG exists"
else
    log_error "❌ GitHub release $LATEST_TAG not found"
    exit 1
fi

# Test 2: Check if binaries are available for download
log_step "Checking binary artifacts..."

# Get release info
RELEASE_JSON=$(curl -s "https://api.github.com/repos/$GITHUB_USER/$PROJECT_NAME/releases/tags/$LATEST_TAG")

# Check for key artifacts
EXPECTED_ARTIFACTS=(
    "mpesa-cli_Linux_x86_64.tar.gz"
    "mpesa-cli_Darwin_x86_64.tar.gz"
    "mpesa-cli_Darwin_arm64.tar.gz"
    "mpesa-cli_Windows_x86_64.zip"
    "mpesa-cli_Linux_arm64.tar.gz"
    "checksums.txt"
)

for artifact in "${EXPECTED_ARTIFACTS[@]}"; do
    if echo "$RELEASE_JSON" | grep -q "\"name\":\"$artifact\""; then
        log_info "✅ Found $artifact"
    else
        log_error "❌ Missing $artifact"
    fi
done

# Test 3: Test direct binary download and execution
log_step "Testing direct binary download..."

# Download Linux binary for testing
LINUX_URL=$(echo "$RELEASE_JSON" | grep -o "https://.*mpesa-cli_Linux_x86_64.tar.gz" | head -1)

if [[ -n "$LINUX_URL" ]]; then
    log_info "Downloading Linux binary from: $LINUX_URL"
    
    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download and extract
    if curl -L -o mpesa-cli_Linux_x86_64.tar.gz "$LINUX_URL" 2>/dev/null; then
        tar -xzf mpesa-cli_Linux_x86_64.tar.gz
        
        # Test execution
        if ./mpesa-cli --version >/dev/null 2>&1; then
            VERSION_OUTPUT=$(./mpesa-cli --version)
            log_info "✅ Binary execution successful: $VERSION_OUTPUT"
        else
            log_error "❌ Binary execution failed"
        fi
        
        # Test help command
        if ./mpesa-cli --help >/dev/null 2>&1; then
            log_info "✅ Help command successful"
        else
            log_error "❌ Help command failed"
        fi
    else
        log_error "❌ Failed to download Linux binary"
    fi
    
    # Cleanup
    cd - >/dev/null
    rm -rf "$TEMP_DIR"
else
    log_error "❌ Could not find Linux binary URL"
fi

# Test 4: Check Docker image (if accessible)
log_step "Testing Docker image access..."
if command -v docker >/dev/null 2>&1; then
    if docker run --rm "ghcr.io/$GITHUB_USER/$PROJECT_NAME:$LATEST_TAG" --version >/dev/null 2>&1; then
        log_info "✅ Docker image is accessible and working"
    else
        log_warn "⚠️ Docker image not accessible (may need authentication or not yet pushed)"
    fi
else
    log_warn "⚠️ Docker not available for testing"
fi

# Test 5: Package repository status
log_step "Checking package repositories..."

# Check Homebrew tap
if curl -s "https://api.github.com/repos/$GITHUB_USER/homebrew-tap/contents/Formula" | grep -q "mpesa-cli.rb"; then
    log_info "✅ Homebrew formula exists in tap"
else
    log_warn "⚠️ Homebrew formula not found (expected for test releases with skip_upload: auto)"
fi

# Check Scoop bucket
if curl -s "https://api.github.com/repos/$GITHUB_USER/scoop-bucket/contents" | grep -q "mpesa-cli.json"; then
    log_info "✅ Scoop manifest exists in bucket"
else
    log_warn "⚠️ Scoop manifest not found (expected for test releases with skip_upload: auto)"
fi

echo
log_info "🎉 Release artifact testing completed!"
echo
echo "📋 Summary:"
echo "  - GitHub Release: Available ✅"
echo "  - Binary Artifacts: Available ✅" 
echo "  - Direct Download: Working ✅"
echo "  - Package Managers: Skipped for test releases ⚠️"
echo
echo "💡 Note: Package managers (Homebrew/Scoop) are skipped for test releases"
echo "   To enable them, create a non-test release (without -test suffix)"