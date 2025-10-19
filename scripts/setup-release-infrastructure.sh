#!/bin/bash

# Setup script for release infrastructure
# This script creates the necessary repositories for package distribution

set -e

# Configuration
GITHUB_USER="martwebber"
CLI_NAME="mpesa-cli"
PROJECT_NAME="mpesa-cli"

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

# Check if we're in a CI environment
is_ci() {
    [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]
}

# Check if running in dry run mode
is_dry_run() {
    [[ "${DRY_RUN:-false}" == "true" ]]
}

# Check authentication
check_auth() {
    log_step "Checking GitHub authentication..."
    
    if is_ci; then
        if [[ -n "$GITHUB_TOKEN" ]]; then
            log_info "Using GITHUB_TOKEN in CI environment"
            return 0
        else
            log_error "GITHUB_TOKEN not set in CI environment"
            return 1
        fi
    else
        # Interactive mode - check gh auth status
        if gh auth status >/dev/null 2>&1; then
            log_info "GitHub CLI is authenticated"
            return 0
        else
            log_error "GitHub CLI not authenticated. Run: gh auth login"
            return 1
        fi
    fi
}

# Create homebrew tap repository
create_homebrew_tap() {
    local repo_name="homebrew-tap"
    log_step "Setting up Homebrew tap repository..."
    
    if is_dry_run; then
        log_info "[DRY RUN] Would create repository: $GITHUB_USER/$repo_name"
        return 0
    fi
    
    # Check if repository exists
    if gh repo view "$GITHUB_USER/$repo_name" >/dev/null 2>&1; then
        log_info "Repository $GITHUB_USER/$repo_name already exists"
        return 0
    fi
    
    log_info "Creating repository: $GITHUB_USER/$repo_name"
    gh repo create "$GITHUB_USER/$repo_name" \
        --public \
        --description "Homebrew tap for $PROJECT_NAME" \
        --clone=false
    
    log_info "✅ Homebrew tap repository created successfully"
}

# Create scoop bucket repository  
create_scoop_bucket() {
    local repo_name="scoop-bucket"
    log_step "Setting up Scoop bucket repository..."
    
    if is_dry_run; then
        log_info "[DRY RUN] Would create repository: $GITHUB_USER/$repo_name"
        return 0
    fi
    
    # Check if repository exists
    if gh repo view "$GITHUB_USER/$repo_name" >/dev/null 2>&1; then
        log_info "Repository $GITHUB_USER/$repo_name already exists"
        return 0
    fi
    
    log_info "Creating repository: $GITHUB_USER/$repo_name"
    gh repo create "$GITHUB_USER/$repo_name" \
        --public \
        --description "Scoop bucket for $PROJECT_NAME" \
        --clone=false
        
    log_info "✅ Scoop bucket repository created successfully"
}

# Main function
main() {
    log_info "� Setting up release infrastructure for $PROJECT_NAME"
    
    if is_dry_run; then
        log_warn "Running in DRY RUN mode - no actual changes will be made"
    fi
    
    # Check prerequisites
    if ! command -v gh >/dev/null 2>&1; then
        log_error "GitHub CLI (gh) is not installed. Please install it first."
        exit 1
    fi
    
    # Check authentication
    if ! check_auth; then
        exit 1
    fi
    
    # Create repositories
    create_homebrew_tap
    create_scoop_bucket
    
    log_info "🎉 Release infrastructure setup completed!"
    log_info ""
    log_info "Next steps:"
    log_info "1. Create a release tag to trigger the pipeline:"
    log_info "   git tag v0.1.0"
    log_info "   git push origin v0.1.0"
    log_info ""
    log_info "2. After successful release, test installations:"
    log_info "   # Homebrew"
    log_info "   brew tap $GITHUB_USER/tap"
    log_info "   brew install $CLI_NAME"
    log_info ""
    log_info "   # Scoop"
    log_info "   scoop bucket add $GITHUB_USER https://github.com/$GITHUB_USER/scoop-bucket"
    log_info "   scoop install $CLI_NAME"
    log_info ""
    log_info "   # Docker"
    log_info "   docker run --rm ghcr.io/$GITHUB_USER/$PROJECT_NAME:latest --version"
}

# Handle script arguments
case "${1:-}" in
    --dry-run)
        export DRY_RUN=true
        main
        ;;
    --help|-h)
        echo "Usage: $0 [--dry-run] [--help]"
        echo ""
        echo "Options:"
        echo "  --dry-run    Show what would be done without making changes"
        echo "  --help       Show this help message"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Run '$0 --help' for usage information"
        exit 1
        ;;
esac