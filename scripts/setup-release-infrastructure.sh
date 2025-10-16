#!/bin/bash
set -e

# Support a DRY_RUN mode to allow safe local testing without making API calls
DRY_RUN=${DRY_RUN:-0}
dry_run() {
    if [[ "$DRY_RUN" == "1" ]]; then
        echo "[DRY_RUN] $*"
    else
        eval "$@"
    fi
}

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
if [[ "$DRY_RUN" != "1" ]] && ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  You're not logged in to GitHub CLI.${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

if [[ "$DRY_RUN" == "1" ]]; then
    echo -e "${YELLOW}[DRY_RUN] Skipping GitHub CLI authentication check${NC}"
    GITHUB_USER="martwebber"  # Use actual username for dry run
else
    GITHUB_USER=$(gh api user | jq -r .login)
fi

if [[ "$DRY_RUN" != "1" ]]; then
    echo -e "${GREEN}✅ GitHub CLI is ready${NC}"
fi

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
        dry_run "gh repo create \"$GITHUB_USER/$repo_name\" --public --description \"$description\""
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
    dry_run "git clone https://github.com/$GITHUB_USER/homebrew-tap.git \"$temp_dir\""
    if [[ "$DRY_RUN" == "1" ]]; then
        echo "[DRY_RUN] Would cd into $temp_dir and initialize files"
    else
        cd "$temp_dir"
    fi
    
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
    if [[ "$DRY_RUN" == "1" ]]; then
        echo "[DRY_RUN] git add . && git commit -m 'Initialize Homebrew tap structure' && git push origin main"
        echo "[DRY_RUN] Cleanup $temp_dir"
    else
        git add .
        git commit -m "Initialize Homebrew tap structure"
        git push origin main
        
        # Cleanup
        cd - > /dev/null
        rm -rf "$temp_dir"
        
        echo -e "${GREEN}✅ Initialized Homebrew tap structure${NC}"
    fi
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
    dry_run "git clone https://github.com/$GITHUB_USER/scoop-bucket.git \"$temp_dir\""
    if [[ "$DRY_RUN" == "1" ]]; then
        echo "[DRY_RUN] Would cd into $temp_dir and initialize files"
    else
        cd "$temp_dir"
    fi
    
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
    if [[ "$DRY_RUN" == "1" ]]; then
        echo "[DRY_RUN] git add . && git commit -m 'Initialize Scoop bucket structure' && git push origin main"
        echo "[DRY_RUN] Cleanup $temp_dir"
    else
        git add .
        git commit -m "Initialize Scoop bucket structure"
        git push origin main
        
        # Cleanup
        cd - > /dev/null
        rm -rf "$temp_dir"
        
        echo -e "${GREEN}✅ Initialized Scoop bucket structure${NC}"
    fi
fi

echo

# Set up GitHub secrets
echo -e "${BLUE}🔐 Setting up GitHub Secrets${NC}"

# Check if we're running in CI with GH_TOKEN already available
if [[ -n "$GH_TOKEN" ]]; then
    echo -e "${GREEN}✅ Running in CI environment with GH_TOKEN available${NC}"
    echo -e "${GREEN}   Token will be used for both Homebrew and Scoop repositories${NC}"
elif [[ "$DRY_RUN" == "1" ]]; then
    echo -e "${YELLOW}[DRY_RUN] Would check for PERSONAL_ACCESS_TOKEN or prompt for input${NC}"
else
    echo
    echo "The release workflow needs a GitHub Personal Access Token to update the package repositories."
    echo "You need to create a token with the following permissions:"
    echo
    echo -e "${YELLOW}PERSONAL_ACCESS_TOKEN:${NC}"
    echo "   - Go to: https://github.com/settings/tokens"
    echo "   - Create a classic token with 'repo' scope"
    echo "   - Copy the token"
    echo
    echo "Note: The same token is used for both Homebrew tap and Scoop bucket repositories."
    echo

    read -p "Enter PERSONAL_ACCESS_TOKEN: " personal_token
    if [[ -n "$personal_token" ]]; then
        dry_run "echo \"$personal_token\" | gh secret set PERSONAL_ACCESS_TOKEN --repo \"$GITHUB_USER/mpesa-cli\""
        echo -e "${GREEN}✅ Set PERSONAL_ACCESS_TOKEN${NC}"
        echo -e "${GREEN}   This token will be used for both Homebrew and Scoop repositories${NC}"
    else
        echo -e "${YELLOW}⚠️  Skipped setting PERSONAL_ACCESS_TOKEN - you can set it later in GitHub Settings > Secrets${NC}"
    fi
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