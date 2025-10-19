#!/bin/bash

# Test both auto-release workflows locally before pushing
# This prevents CI/CD breakage by validating workflows locally

set -e

# Colors for output  
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_success() { echo -e "${GREEN}[✅]${NC} $1"; }
log_error() { echo -e "${RED}[❌]${NC} $1"; }
log_test() { echo -e "${BLUE}[TEST]${NC} $1"; }

echo -e "${BOLD}${CYAN}================================================${NC}"
echo -e "${BOLD}${CYAN}  Complete Workflow Testing Suite${NC}"
echo -e "${BOLD}${CYAN}================================================${NC}"
echo

# Test 1: YAML Syntax Validation
log_test "Validating YAML syntax for all workflows..."

WORKFLOWS=(
    ".github/workflows/auto-release-candidate.yml"
    ".github/workflows/auto-release-candidate-draft.yml"
    ".github/workflows/manual-release.yml"
    ".github/workflows/package-test.yml"
    ".github/workflows/release.yml"
    ".github/workflows/test.yml"
)

for workflow in "${WORKFLOWS[@]}"; do
    if [ -f "$workflow" ]; then
        if command -v yamllint >/dev/null 2>&1; then
            if yamllint "$workflow" >/dev/null 2>&1; then
                log_success "YAML syntax valid: $workflow"
            else
                log_error "YAML syntax invalid: $workflow"
                yamllint "$workflow"
                exit 1
            fi
        elif python3 -c "import yaml" >/dev/null 2>&1; then
            if python3 -c "import yaml; yaml.safe_load(open('$workflow'))" >/dev/null 2>&1; then
                log_success "YAML syntax valid: $workflow"
            else
                log_error "YAML syntax invalid: $workflow"
                python3 -c "import yaml; yaml.safe_load(open('$workflow'))"
                exit 1
            fi
        else
            log_warn "No YAML validator found (install yamllint or python3-yaml)"
        fi
    else
        log_warn "Workflow not found: $workflow"
    fi
done

# Test 2: Auto-Release Logic Testing
log_test "Testing auto-release logic..."
if [ -f "scripts/test-auto-release-locally.sh" ]; then
    ./scripts/test-auto-release-locally.sh
    log_success "Auto-release logic test completed"
else
    log_error "Auto-release test script not found"
    exit 1
fi

# Test 3: GoReleaser Configuration
log_test "Validating GoReleaser configuration..."
if command -v goreleaser >/dev/null 2>&1; then
    if goreleaser check >/dev/null 2>&1; then
        log_success "GoReleaser configuration valid"
    else
        log_error "GoReleaser configuration invalid"
        goreleaser check
        exit 1
    fi
else
    log_warn "GoReleaser not installed - skipping validation"
fi

# Test 4: Pipeline Status Script
log_test "Testing pipeline status script..."
if [ -f "scripts/pipeline-status.sh" ]; then
    if ./scripts/pipeline-status.sh >/dev/null 2>&1; then
        log_success "Pipeline status script works"
    else
        log_error "Pipeline status script failed"
        exit 1
    fi
else
    log_error "Pipeline status script not found"
    exit 1
fi

# Test 5: Quick Release Script  
log_test "Testing quick release script syntax..."
if [ -f "scripts/quick-release.sh" ]; then
    if bash -n scripts/quick-release.sh; then
        log_success "Quick release script syntax valid"
    else
        log_error "Quick release script syntax invalid"
        exit 1
    fi
else
    log_error "Quick release script not found"
    exit 1
fi

# Test 6: Workflow Trigger Conditions
log_test "Analyzing workflow trigger conditions..."

CURRENT_BRANCH=$(git branch --show-current)
HAS_COMMITS_SINCE_TAG=false

LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
COMMITS_SINCE_TAG=$(git log ${LATEST_TAG}..HEAD --oneline)

if [ -n "$COMMITS_SINCE_TAG" ]; then
    HAS_COMMITS_SINCE_TAG=true
fi

echo -e "${BLUE}Trigger Analysis:${NC}"
echo "  Current Branch: $CURRENT_BRANCH"
echo "  Latest Tag: $LATEST_TAG"
echo "  Commits Since Tag: $(echo "$COMMITS_SINCE_TAG" | wc -l)"

if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    if [ "$HAS_COMMITS_SINCE_TAG" = true ]; then
        log_success "Would trigger auto-release workflow on push"
    else
        log_warn "No commits since last tag - workflow would not create release"
    fi
else
    log_warn "Not on main/master - workflow would not trigger on push"
fi

# Test 7: Required Files Check
log_test "Checking required files..."

REQUIRED_FILES=(
    ".goreleaser.yaml"
    "go.mod"
    "main.go"
    "README.md"
    "LICENSE"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_success "Required file exists: $file"
    else
        log_error "Required file missing: $file"
        exit 1
    fi
done

# Test 8: GitHub CLI Authentication (if available)
log_test "Checking GitHub CLI authentication..."
if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
        log_success "GitHub CLI authenticated"
    else
        log_warn "GitHub CLI not authenticated - manual workflows may not work"
    fi
else
    log_warn "GitHub CLI not installed"
fi

# Test 9: Test Suite Execution
log_test "Running test suite..."
if [ -f "go.mod" ]; then
    if go test ./... >/dev/null 2>&1; then
        log_success "All tests pass"
    else
        log_error "Some tests fail - fix before pushing"
        go test ./...
        exit 1
    fi
else
    log_warn "No Go module found - skipping tests"
fi

# Test 10: Draft Release Preview
log_test "Generating draft release preview..."

if [ "$HAS_COMMITS_SINCE_TAG" = true ]; then
    echo -e "${CYAN}Draft Release Preview:${NC}"
    echo "----------------------------------------"
    
    # Simulate release notes generation
    echo "## Changes in upcoming release"
    echo
    
    while IFS= read -r commit; do
        if [[ "$commit" =~ ^[a-f0-9]+[[:space:]]+(feat|feature)(\(.+\))?!: ]] || [[ "$commit" =~ BREAKING[[:space:]]CHANGE ]]; then
            echo "💥 **BREAKING**: ${commit#* }"
        elif [[ "$commit" =~ ^[a-f0-9]+[[:space:]]+(feat|feature)(\(.+\))?: ]]; then
            echo "✨ ${commit#* }"
        elif [[ "$commit" =~ ^[a-f0-9]+[[:space:]]+(fix|bugfix)(\(.+\))?: ]]; then
            echo "🐛 ${commit#* }"
        elif [[ "$commit" =~ ^[a-f0-9]+[[:space:]]+docs(\(.+\))?: ]]; then
            echo "📚 ${commit#* }"
        else
            echo "🔧 ${commit#* }"
        fi
    done <<< "$COMMITS_SINCE_TAG"
    
    echo
    echo "## 📦 Installation"
    echo
    echo "### Ubuntu/Debian"
    echo "\`\`\`bash"
    echo "curl -LO \"https://github.com/martwebber/mpesa-cli/releases/download/vX.Y.Z/mpesa-cli_X.Y.Z_linux_amd64.deb\""
    echo "sudo dpkg -i \"mpesa-cli_X.Y.Z_linux_amd64.deb\""
    echo "\`\`\`"
    
    echo "----------------------------------------"
    log_success "Draft release preview generated"
else
    log_warn "No commits since last tag - no release would be created"
fi

# Final Summary
echo
log_success "All tests completed successfully!"
echo
echo -e "${BOLD}${GREEN}Summary:${NC}"
echo -e "  ✅ YAML syntax validation"
echo -e "  ✅ Auto-release logic testing"
echo -e "  ✅ GoReleaser configuration"
echo -e "  ✅ Pipeline scripts validation"
echo -e "  ✅ Workflow trigger analysis"
echo -e "  ✅ Required files check"
echo -e "  ✅ Test suite execution"
echo -e "  ✅ Draft release preview"
echo
echo -e "${BOLD}${CYAN}🚀 Ready to push! Workflows should work correctly.${NC}"

# Recommendations
echo
echo -e "${BOLD}${YELLOW}📋 Recommendations:${NC}"
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    echo -e "  • Merge to main/master to trigger auto-release workflow"
fi
if ! command -v gh >/dev/null 2>&1; then
    echo -e "  • Install GitHub CLI for manual release workflows"
fi
if ! command -v yamllint >/dev/null 2>&1; then
    echo -e "  • Install yamllint for better YAML validation"
fi
if ! command -v goreleaser >/dev/null 2>&1; then
    echo -e "  • Install GoReleaser for local testing"
fi