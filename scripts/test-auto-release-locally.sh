#!/bin/bash

# Test auto-release-candidate workflow locally
# This simulates the GitHub Actions workflow without actually creating releases

set -e

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

log_error() {
    echo -e "${RED}[❌]${NC} $1"
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

echo -e "${BOLD}${CYAN}================================================${NC}"
echo -e "${BOLD}${CYAN}  Auto Release Candidate - Local Testing${NC}"
echo -e "${BOLD}${CYAN}================================================${NC}"
echo

# Test 1: Check if we're in a git repository
log_test "Checking git repository..."
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log_error "Not in a git repository"
    exit 1
fi
log_success "Git repository detected"

# Test 2: Get latest tag (simulating workflow)
log_test "Getting latest tag..."
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
log_info "Latest tag: $LATEST_TAG"

# Test 3: Get commits since last tag
log_test "Analyzing commits since last tag..."
if [ "$LATEST_TAG" = "v0.0.0" ]; then
    COMMITS=$(git log --oneline | head -20)
    log_info "No previous tags found, analyzing recent commits"
else
    COMMITS=$(git log ${LATEST_TAG}..HEAD --oneline)
fi

if [ -z "$COMMITS" ]; then
    log_warn "No commits found since last tag"
    echo "No release needed"
    exit 0
fi

echo -e "${BLUE}Commits since ${LATEST_TAG}:${NC}"
echo "$COMMITS" | head -10
if [ $(echo "$COMMITS" | wc -l) -gt 10 ]; then
    echo "... and $(($(echo "$COMMITS" | wc -l) - 10)) more"
fi
echo

# Test 4: Analyze commit messages for semantic versioning
log_test "Analyzing commit messages for semantic versioning..."

MAJOR_CHANGE=false
MINOR_CHANGE=false
PATCH_CHANGE=false

while IFS= read -r commit; do
    if [[ "$commit" =~ ^[a-f0-9]+[[:space:]]+(feat|feature)(\(.+\))?!: ]] || [[ "$commit" =~ BREAKING[[:space:]]CHANGE ]]; then
        MAJOR_CHANGE=true
        echo -e "  ${RED}💥 MAJOR:${NC} $commit"
    elif [[ "$commit" =~ ^[a-f0-9]+[[:space:]]+(feat|feature)(\(.+\))?: ]]; then
        MINOR_CHANGE=true
        echo -e "  ${GREEN}✨ MINOR:${NC} $commit"
    elif [[ "$commit" =~ ^[a-f0-9]+[[:space:]]+(fix|bugfix|patch)(\(.+\))?: ]]; then
        PATCH_CHANGE=true
        echo -e "  ${YELLOW}🐛 PATCH:${NC} $commit"
    else
        echo -e "  ${BLUE}🔧 OTHER:${NC} $commit"
    fi
done <<< "$COMMITS"

echo

# Test 5: Determine version bump
log_test "Determining version bump..."

if [ "$MAJOR_CHANGE" = true ]; then
    VERSION_TYPE="major"
elif [ "$MINOR_CHANGE" = true ]; then
    VERSION_TYPE="minor"
elif [ "$PATCH_CHANGE" = true ]; then
    VERSION_TYPE="patch"
else
    VERSION_TYPE="none"
fi

log_info "Version bump type: $VERSION_TYPE"

# Test 6: Calculate next version
if [ "$VERSION_TYPE" != "none" ]; then
    log_test "Calculating next version..."
    CURRENT_VERSION=${LATEST_TAG#v}
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
    
    case $VERSION_TYPE in
        major)
            NEXT_VERSION="v$((MAJOR + 1)).0.0"
            ;;
        minor)
            NEXT_VERSION="v${MAJOR}.$((MINOR + 1)).0"
            ;;
        patch)
            NEXT_VERSION="v${MAJOR}.${MINOR}.$((PATCH + 1))"
            ;;
    esac
    
    log_success "Next version: $LATEST_TAG → $NEXT_VERSION"
else
    log_info "No version bump needed"
    echo -e "${YELLOW}No release would be created${NC}"
    exit 0
fi

# Test 7: Generate release notes preview
log_test "Generating release notes preview..."

RELEASE_NOTES="## Changes in $NEXT_VERSION

"

# Add commit details with emojis
while IFS= read -r commit; do
    if [[ "$commit" =~ ^[a-f0-9]+[[:space:]]+(feat|feature)(\(.+\))?!: ]] || [[ "$commit" =~ BREAKING[[:space:]]CHANGE ]]; then
        RELEASE_NOTES="${RELEASE_NOTES}💥 **BREAKING**: ${commit#* }
"
    elif [[ "$commit" =~ ^[a-f0-9]+[[:space:]]+(feat|feature)(\(.+\))?: ]]; then
        RELEASE_NOTES="${RELEASE_NOTES}✨ ${commit#* }
"
    elif [[ "$commit" =~ ^[a-f0-9]+[[:space:]]+(fix|bugfix)(\(.+\))?: ]]; then
        RELEASE_NOTES="${RELEASE_NOTES}🐛 ${commit#* }
"
    elif [[ "$commit" =~ ^[a-f0-9]+[[:space:]]+docs(\(.+\))?: ]]; then
        RELEASE_NOTES="${RELEASE_NOTES}📚 ${commit#* }
"
    elif [[ "$commit" =~ ^[a-f0-9]+[[:space:]]+perf(\(.+\))?: ]]; then
        RELEASE_NOTES="${RELEASE_NOTES}⚡ ${commit#* }
"
    elif [[ "$commit" =~ ^[a-f0-9]+[[:space:]]+refactor(\(.+\))?: ]]; then
        RELEASE_NOTES="${RELEASE_NOTES}♻️ ${commit#* }
"
    else
        RELEASE_NOTES="${RELEASE_NOTES}🔧 ${commit#* }
"
    fi
done <<< "$COMMITS"

# Add installation instructions
RELEASE_NOTES="${RELEASE_NOTES}

## 📦 Installation

### Ubuntu/Debian
\`\`\`bash
curl -LO \"https://github.com/martwebber/mpesa-cli/releases/download/${NEXT_VERSION}/mpesa-cli_${NEXT_VERSION#v}_linux_amd64.deb\"
sudo dpkg -i \"mpesa-cli_${NEXT_VERSION#v}_linux_amd64.deb\"
\`\`\`

### Homebrew (macOS/Linux)
\`\`\`bash
brew tap martwebber/tap && brew install mpesa-cli
\`\`\`

### Scoop (Windows)
\`\`\`bash
scoop bucket add martwebber https://github.com/martwebber/scoop-bucket
scoop install mpesa-cli
\`\`\`

### Docker
\`\`\`bash
docker run --rm ghcr.io/martwebber/mpesa-cli:${NEXT_VERSION} --version
\`\`\`

**Full Changelog**: https://github.com/martwebber/mpesa-cli/compare/${LATEST_TAG}...${NEXT_VERSION}"

echo -e "${CYAN}Generated Release Notes:${NC}"
echo "----------------------------------------"
echo "$RELEASE_NOTES"
echo "----------------------------------------"
echo

# Test 8: Simulate workflow conditions
log_test "Simulating workflow conditions..."

# Check if this would trigger on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    log_success "Would trigger on branch: $CURRENT_BRANCH"
else
    log_warn "Would NOT trigger on branch: $CURRENT_BRANCH (not main/master)"
fi

# Test 9: Validate release notes format
log_test "Validating release notes format..."

if echo "$RELEASE_NOTES" | grep -q "## Changes in"; then
    log_success "Release notes have proper header"
else
    log_error "Release notes missing proper header"
fi

if echo "$RELEASE_NOTES" | grep -q "## 📦 Installation"; then
    log_success "Installation instructions included"
else
    log_error "Installation instructions missing"
fi

if echo "$RELEASE_NOTES" | grep -q "Full Changelog"; then
    log_success "Changelog link included"
else
    log_error "Changelog link missing"
fi

# Test 10: Summary
echo
log_success "Local testing complete!"
echo
echo -e "${BOLD}${GREEN}Summary:${NC}"
echo -e "  Current Version: ${LATEST_TAG}"
echo -e "  Next Version: ${NEXT_VERSION}"
echo -e "  Change Type: ${VERSION_TYPE}"
echo -e "  Commits Analyzed: $(echo "$COMMITS" | wc -l)"
echo
echo -e "${BOLD}${YELLOW}What would happen in GitHub Actions:${NC}"
echo -e "  1. ✅ Analyze commits (completed above)"
echo -e "  2. ✅ Determine version bump (${VERSION_TYPE})"
echo -e "  3. 🔄 Run test suite (use: npm test / go test / etc.)"
echo -e "  4. 📝 Create draft release with generated notes"
echo -e "  5. 💬 Notify team about new draft release"
echo
echo -e "${BOLD}${CYAN}Ready to push? Run this workflow will create a draft release!${NC}"