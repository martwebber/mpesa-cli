#!/bin/bash

# Pipeline status summary script
# Shows the current status of the release pipeline and package availability

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✅]${NC} $1"
}

log_pending() {
    echo -e "${YELLOW}[⏳]${NC} $1"
}

log_error() {
    echo -e "${RED}[❌]${NC} $1"
}

echo -e "${BOLD}${CYAN}================================================${NC}"
echo -e "${BOLD}${CYAN}  M-Pesa CLI Release Pipeline Status${NC}"
echo -e "${BOLD}${CYAN}================================================${NC}"
echo

# Get latest releases
echo -e "${BLUE}📋 Recent Releases:${NC}"
RELEASES=$(curl -s "https://api.github.com/repos/martwebber/mpesa-cli/releases" | grep '"tag_name"' | head -3 | sed 's/.*"tag_name": "\([^"]*\)".*/\1/')
echo "$RELEASES" | while read -r tag; do
    if [[ "$tag" == *"-test" ]]; then
        echo "  🧪 $tag (test release)"
    else
        echo "  🚀 $tag (production release)"
    fi
done
echo

# Check package repositories
echo -e "${BLUE}📦 Package Manager Status:${NC}"

# Homebrew
if curl -sf "https://api.github.com/repos/martwebber/homebrew-tap/contents/Formula/mpesa-cli.rb" > /dev/null 2>&1; then
    log_success "Homebrew formula available"
    echo "   Install: brew tap martwebber/tap && brew install mpesa-cli"
else
    log_pending "Homebrew formula not yet available"
    echo "   This is normal for new releases - formula should be available within 5-10 minutes"
fi

# Scoop
if curl -sf "https://api.github.com/repos/martwebber/scoop-bucket/contents/mpesa-cli.json" > /dev/null 2>&1; then
    log_success "Scoop manifest available"
    echo "   Install: scoop bucket add martwebber https://github.com/martwebber/scoop-bucket && scoop install mpesa-cli"
else
    log_pending "Scoop manifest not yet available"
    echo "   This is normal for new releases - manifest should be available within 5-10 minutes"
fi

# Docker
LATEST_PROD_TAG=$(curl -s "https://api.github.com/repos/martwebber/mpesa-cli/releases" | grep '"tag_name"' | grep -v 'test"' | head -1 | sed 's/.*"tag_name": "\([^"]*\)".*/\1/')
if [[ -n "$LATEST_PROD_TAG" ]] && docker run --rm "ghcr.io/martwebber/mpesa-cli:$LATEST_PROD_TAG" --version >/dev/null 2>&1; then
    log_success "Docker image available"
    echo "   Run: docker run --rm ghcr.io/martwebber/mpesa-cli:$LATEST_PROD_TAG --version"
elif [[ -n "$LATEST_PROD_TAG" ]]; then
    log_pending "Docker image may be building"
    echo "   Try: docker run --rm ghcr.io/martwebber/mpesa-cli:$LATEST_PROD_TAG --version"
else
    log_error "No production release found"
fi

echo

# Direct download status
echo -e "${BLUE}💾 Direct Downloads:${NC}"
if [[ -n "$LATEST_PROD_TAG" ]]; then
    RELEASE_API="https://api.github.com/repos/martwebber/mpesa-cli/releases/tags/$LATEST_PROD_TAG"
    if curl -sf "$RELEASE_API" >/dev/null 2>&1; then
        log_success "Release binaries available for $LATEST_PROD_TAG"
        echo "   Download: https://github.com/martwebber/mpesa-cli/releases/tag/$LATEST_PROD_TAG"
        
        # List available platforms
        PLATFORMS=$(curl -s "$RELEASE_API" | grep '"name".*\.tar\.gz\|"name".*\.zip' | sed 's/.*"name": "\([^"]*\)".*/\1/' | head -5)
        echo "   Platforms:"
        echo "$PLATFORMS" | while read -r platform; do
            echo "     • $platform"
        done
    else
        log_error "Release binaries not found for $LATEST_PROD_TAG"
    fi
else
    log_error "No production release tag found"
fi

echo

# GitHub Actions status
echo -e "${BLUE}🔄 Pipeline Status:${NC}"
log_info "Monitor workflows at: https://github.com/martwebber/mpesa-cli/actions"

echo

# Usage examples
echo -e "${BLUE}📖 Installation Examples:${NC}"
echo -e "${CYAN}# macOS/Linux (Homebrew)${NC}"
echo "brew tap martwebber/tap"
echo "brew install mpesa-cli"
echo
echo -e "${CYAN}# Windows (Scoop)${NC}"
echo "scoop bucket add martwebber https://github.com/martwebber/scoop-bucket"
echo "scoop install mpesa-cli"
echo
echo -e "${CYAN}# Docker (Any platform)${NC}"
echo "docker run --rm ghcr.io/martwebber/mpesa-cli:latest --version"
echo
echo -e "${CYAN}# Direct Download${NC}"
echo "# Visit: https://github.com/martwebber/mpesa-cli/releases/latest"
echo

echo -e "${BOLD}${GREEN}🎉 Pipeline Status Check Complete!${NC}"