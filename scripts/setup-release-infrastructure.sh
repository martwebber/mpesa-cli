#!/bin/bash
set -e

echo "🚀 Setting up M-Pesa CLI Release Infrastructure"
echo "=============================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}This script will help you set up the complete release infrastructure for M-Pesa CLI.${NC}"
echo
echo "What will be created:"
echo "  1. GitHub repositories for package distribution"
echo "  2. GitHub secrets for automated releases" 
echo "  3. Instructions for testing the release pipeline"
echo

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed.${NC}"
    echo "Please install it from: https://cli.github.com/"
    echo
    echo "On macOS: brew install gh"
    echo "On Ubuntu: sudo apt install gh"
    echo "On Windows: winget install GitHub.cli"
    exit 1
fi

# Check if user is logged in to GitHub CLI
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  You're not logged in to GitHub CLI.${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI is ready${NC}"
echo

# Get current user
GITHUB_USER=$(gh api user | jq -r .login)
echo -e "${BLUE}GitHub user: ${GITHUB_USER}${NC}"
echo

# Function to create repository if it doesn't exist
create_repo_if_not_exists() {
    local repo_name=$1
    local description=$2
    
    echo -e "${BLUE}Checking repository: ${repo_name}${NC}"
    
    if gh repo view "$GITHUB_USER/$repo_name" &> /dev/null; then
        echo -e "${YELLOW}⚠️  Repository $repo_name already exists${NC}"
    else
        echo -e "${BLUE}Creating repository: $repo_name${NC}"
        gh repo create "$repo_name" --public --description "$description" --confirm
        echo -e "${GREEN}✅ Created repository: $repo_name${NC}"
    fi
}

# Create Homebrew tap repository
echo -e "${BLUE}📦 Setting up Homebrew Tap${NC}"
create_repo_if_not_exists "homebrew-tap" "Homebrew formulae for M-Pesa CLI"

# Initialize Homebrew tap with basic structure
if ! gh repo view "$GITHUB_USER/homebrew-tap" -- README.md &> /dev/null; then
    echo -e "${BLUE}Initializing Homebrew tap structure${NC}"
    
    # Clone the repo temporarily
    temp_dir=$(mktemp -d)
    git clone "https://github.com/$GITHUB_USER/homebrew-tap.git" "$temp_dir"
    cd "$temp_dir"
    
    # Create README
    cat > README.md << EOF
# Homebrew Tap for M-Pesa CLI

This is the official Homebrew tap for M-Pesa CLI.

## Installation

\`\`\`bash
brew tap $GITHUB_USER/tap
brew install mpesa-cli
\`\`\`

## Available Formulae

- **mpesa-cli**: A command-line interface for M-Pesa API operations

## About

This tap is automatically maintained by GoReleaser during the release process.
EOF

    # Create Formula directory
    mkdir -p Formula
    
    # Commit and push
    git add .
    git commit -m "Initialize Homebrew tap structure"
    git push origin main
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}✅ Initialized Homebrew tap structure${NC}"
fi

echo

# Create Scoop bucket repository  
echo -e "${BLUE}📦 Setting up Scoop Bucket${NC}"
create_repo_if_not_exists "scoop-bucket" "Scoop bucket for M-Pesa CLI"

# Initialize Scoop bucket with basic structure
if ! gh repo view "$GITHUB_USER/scoop-bucket" -- README.md &> /dev/null; then
    echo -e "${BLUE}Initializing Scoop bucket structure${NC}"
    
    # Clone the repo temporarily
    temp_dir=$(mktemp -d)
    git clone "https://github.com/$GITHUB_USER/scoop-bucket.git" "$temp_dir"
    cd "$temp_dir"
    
    # Create README
    cat > README.md << EOF
# Scoop Bucket for M-Pesa CLI

This is the official Scoop bucket for M-Pesa CLI.

## Installation

\`\`\`powershell
scoop bucket add $GITHUB_USER https://github.com/$GITHUB_USER/scoop-bucket.git
scoop install mpesa-cli
\`\`\`

## Available Packages

- **mpesa-cli**: A command-line interface for M-Pesa API operations

## About

This bucket is automatically maintained by GoReleaser during the release process.
EOF

    # Commit and push
    git add .
    git commit -m "Initialize Scoop bucket structure"
    git push origin main
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}✅ Initialized Scoop bucket structure${NC}"
fi

echo

# Set up GitHub secrets
echo -e "${BLUE}🔐 Setting up GitHub Secrets${NC}"
echo
echo "The release workflow needs GitHub Personal Access Tokens to update the package repositories."
echo "You need to create tokens with the following permissions:"
echo
echo -e "${YELLOW}1. PERSONAL_ACCESS_TOKEN:${NC}"
echo "   - Go to: https://github.com/settings/tokens"
echo "   - Create a classic token with 'repo' scope"
echo "   - Copy the token"
echo

read -p "Enter PERSONAL_ACCESS_TOKEN: " homebrew_token
if [[ -n "$homebrew_token" ]]; then
    echo "$homebrew_token" | gh secret set PERSONAL_ACCESS_TOKEN --repo "$GITHUB_USER/mpesa-cli"
    echo -e "${GREEN}✅ Set PERSONAL_ACCESS_TOKEN${NC}"
fi

echo
echo -e "${YELLOW}2. PERSONAL_ACCESS_TOKEN:${NC}"
echo "   - You can use the same token as above"
echo

read -p "Enter PERSONAL_ACCESS_TOKEN (or press Enter to use the same token): " scoop_token
if [[ -z "$scoop_token" && -n "$homebrew_token" ]]; then
    scoop_token="$homebrew_token"
fi

if [[ -n "$scoop_token" ]]; then
    echo "$scoop_token" | gh secret set PERSONAL_ACCESS_TOKEN --repo "$GITHUB_USER/mpesa-cli"
    echo -e "${GREEN}✅ Set PERSONAL_ACCESS_TOKEN${NC}"
fi

echo
echo -e "${GREEN}🎉 Release infrastructure setup complete!${NC}"
echo
echo -e "${BLUE}Next steps:${NC}"
echo "1. Test the release pipeline by creating a test tag:"
echo -e "   ${YELLOW}git tag v0.1.0-test${NC}"
echo -e "   ${YELLOW}git push origin v0.1.0-test${NC}"
echo
echo "2. Monitor the GitHub Actions workflow:"
echo -e "   ${YELLOW}https://github.com/$GITHUB_USER/mpesa-cli/actions${NC}"
echo
echo "3. Once working, create a real release:"
echo -e "   ${YELLOW}git tag v1.0.0${NC}"
echo -e "   ${YELLOW}git push origin v1.0.0${NC}"
echo
echo -e "${BLUE}Package installation will be available at:${NC}"
echo "  • Homebrew: brew install $GITHUB_USER/tap/mpesa-cli" 
echo "  • Scoop: scoop bucket add $GITHUB_USER https://github.com/$GITHUB_USER/scoop-bucket.git && scoop install mpesa-cli"
echo "  • Docker: ghcr.io/$GITHUB_USER/mpesa-cli:latest"
echo "  • GitHub Releases: Direct binary downloads"
echo