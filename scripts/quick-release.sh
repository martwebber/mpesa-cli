#!/bin/bash

# Quick release script for M-Pesa CLI
# Usage: ./scripts/quick-release.sh [version] [notes]

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) is required but not installed"
    echo "Install: https://cli.github.com/"
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    log_warn "You're on branch '$CURRENT_BRANCH', not main/master"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Function to suggest next version
suggest_version() {
    LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    CURRENT_VERSION=${LATEST_TAG#v}
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
    
    echo -e "${BLUE}Current version: ${LATEST_TAG}${NC}"
    echo -e "${BLUE}Suggested versions:${NC}"
    echo "  Patch: v${MAJOR}.${MINOR}.$((PATCH + 1))"
    echo "  Minor: v${MAJOR}.$((MINOR + 1)).0"
    echo "  Major: v$((MAJOR + 1)).0.0"
    echo
}

# Function to show recent commits
show_recent_commits() {
    LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [ -n "$LATEST_TAG" ]; then
        echo -e "${BLUE}Changes since ${LATEST_TAG}:${NC}"
        git log ${LATEST_TAG}..HEAD --oneline | head -10
    else
        echo -e "${BLUE}Recent commits:${NC}"
        git log --oneline | head -10
    fi
    echo
}

# Get version from argument or prompt
if [ -n "$1" ]; then
    VERSION="$1"
else
    suggest_version
    show_recent_commits
    
    read -p "Enter version to release (e.g., v1.0.24): " VERSION
fi

# Validate version format
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "Invalid version format: $VERSION"
    log_info "Expected format: v1.2.3"
    exit 1
fi

# Check if tag already exists
if git tag -l | grep -q "^${VERSION}$"; then
    log_error "Tag $VERSION already exists"
    exit 1
fi

# Get release notes from argument or prompt
if [ -n "$2" ]; then
    RELEASE_NOTES="$2"
else
    echo -e "${BLUE}Enter release notes (or press Enter for auto-generated):${NC}"
    read -r RELEASE_NOTES
fi

# Confirm release
echo
echo -e "${BLUE}🚀 Release Summary:${NC}"
echo "  Version: $VERSION"
echo "  Notes: ${RELEASE_NOTES:-Auto-generated}"
echo "  Branch: $CURRENT_BRANCH"
echo
read -p "Proceed with release? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Release cancelled"
    exit 0
fi

# Run the release
log_info "Triggering release workflow..."

if [ -n "$RELEASE_NOTES" ]; then
    gh workflow run "Manual Release" \
        -f version="$VERSION" \
        -f release_notes="$RELEASE_NOTES"
else
    gh workflow run "Manual Release" \
        -f version="$VERSION"
fi

log_info "✅ Release workflow started for $VERSION"
log_info "Monitor progress: https://github.com/$(gh repo view --json owner,name -q '.owner.login + "/" + .name')/actions"

# Wait a moment and show status
sleep 2
echo
log_info "Recent workflow runs:"
gh run list --limit 3