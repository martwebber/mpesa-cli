#!/bin/bash

# Local pipeline testing script
# This script tests all aspects of the release pipeline locally before pushing to GitHub

# Note: Not using set -e to allow graceful error handling in tests

# Configuration
PROJECT_NAME="mpesa-cli"
GITHUB_USER="martwebber"
TEST_TAG_PREFIX="test-local"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

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

log_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✅ PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[❌ FAIL]${NC} $1"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("$1")
}

banner() {
    echo
    echo -e "${BOLD}${CYAN}================================================${NC}"
    echo -e "${BOLD}${CYAN}  M-Pesa CLI Pipeline Local Testing Suite${NC}"
    echo -e "${BOLD}${CYAN}================================================${NC}"
    echo
}

cleanup() {
    if [[ "${CLEANUP_ENABLED:-1}" == "1" ]]; then
        log_step "Cleaning up test artifacts..."
        
        # Remove test binaries
        rm -f mpesa-cli-test mpesa-cli-temp 2>/dev/null || true
        
        # Remove test completions
        rm -rf test-completions/ 2>/dev/null || true
        
        # Remove test Docker images
        if command -v docker >/dev/null 2>&1; then
            docker rmi mpesa-cli-test:latest >/dev/null 2>&1 || true
        fi
        
        log_info "Cleanup completed"
    fi
}

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check required tools
    if ! command -v go >/dev/null 2>&1; then
        missing_tools+=("go")
    fi
    
    if ! command -v git >/dev/null 2>&1; then
        missing_tools+=("git")
    fi
    
    if ! command -v gh >/dev/null 2>&1; then
        log_warn "GitHub CLI (gh) not found - repository checks will be skipped"
    fi
    
    if ! command -v docker >/dev/null 2>&1; then
        log_warn "Docker not found - Docker build tests will be skipped"
    fi
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_tools+=("curl")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    log_success "All required prerequisites available"
}

check_git_status() {
    log_step "Checking Git repository status..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_fail "Not in a Git repository"
        return 1
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        log_warn "Repository has uncommitted changes"
        git status --porcelain
        echo
        read -p "Continue with uncommitted changes? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Aborted due to uncommitted changes"
            exit 1
        fi
    fi
    
    log_success "Git repository status check passed"
}

check_existing_tags() {
    log_step "Checking existing tags..."
    
    # Fetch latest tags from origin
    log_info "Fetching tags from origin..."
    git fetch origin --tags >/dev/null 2>&1 || {
        log_warn "Could not fetch tags from origin (may not be connected)"
    }
    
    # List recent tags
    local recent_tags=$(git tag --sort=-version:refname | head -10)
    if [[ -n "$recent_tags" ]]; then
        log_info "Recent tags:"
        echo "$recent_tags" | while read -r tag; do
            echo "  - $tag"
        done
    else
        log_info "No existing tags found"
    fi
    
    # Suggest next version
    local latest_tag=$(git tag --sort=-version:refname | head -1)
    if [[ -n "$latest_tag" ]]; then
        log_info "Latest tag: $latest_tag"
        
        # Extract version components
        if [[ $latest_tag =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)(-.*)?$ ]]; then
            local major=${BASH_REMATCH[1]}
            local minor=${BASH_REMATCH[2]}
            local patch=${BASH_REMATCH[3]}
            local suffix=${BASH_REMATCH[4]}
            
            local next_patch=$((patch + 1))
            log_info "Suggested next version: v${major}.${minor}.${next_patch}"
        fi
    else
        log_info "Suggested initial version: v1.0.0"
    fi
    
    log_success "Tag check completed"
}

test_go_build() {
    log_test "Testing Go build..."
    
    # Test basic build
    if go build -o mpesa-cli-test . >/dev/null 2>&1; then
        log_success "Go build successful"
    else
        log_fail "Go build failed"
        return 1
    fi
    
    # Test binary execution
    if ./mpesa-cli-test --version >/dev/null 2>&1; then
        log_success "Binary execution test passed"
    else
        log_fail "Binary execution test failed"
        return 1
    fi
    
    # Test cross-compilation for key platforms
    local platforms=(
        "linux/amd64"
        "darwin/amd64"
        "windows/amd64"
        "linux/arm64"
    )
    
    for platform in "${platforms[@]}"; do
        local goos=${platform%/*}
        local goarch=${platform#*/}
        
        log_info "Testing cross-compilation for $platform..."
        if CGO_ENABLED=0 GOOS=$goos GOARCH=$goarch go build -o mpesa-cli-$goos-$goarch . >/dev/null 2>&1; then
            log_success "Cross-compilation for $platform successful"
            rm -f mpesa-cli-$goos-$goarch
        else
            log_fail "Cross-compilation for $platform failed"
        fi
    done
}

test_go_modules() {
    log_test "Testing Go modules..."
    
    # Test go mod tidy
    if go mod tidy >/dev/null 2>&1; then
        log_success "go mod tidy successful"
    else
        log_fail "go mod tidy failed"
        return 1
    fi
    
    # Test go mod verify
    if go mod verify >/dev/null 2>&1; then
        log_success "go mod verify successful"
    else
        log_fail "go mod verify failed"
        return 1
    fi
    
    # Check for Go version consistency
    local go_mod_version=$(grep '^go ' go.mod | awk '{print $2}')
    log_info "Go version in go.mod: $go_mod_version"
    
    # Check Dockerfile Go version
    if [[ -f Dockerfile ]]; then
        local dockerfile_version=$(grep 'FROM.*golang:' Dockerfile | head -1 | sed 's/.*golang:\([0-9.]*\).*/\1/')
        log_info "Go version in Dockerfile: $dockerfile_version"
        
        if [[ "$go_mod_version" == "$dockerfile_version"* ]] || [[ "$dockerfile_version" == "$go_mod_version"* ]]; then
            log_success "Go version consistency check passed"
        else
            log_warn "Go version mismatch between go.mod ($go_mod_version) and Dockerfile ($dockerfile_version)"
        fi
    fi
}

test_completions_generation() {
    log_test "Testing completions generation..."
    
    mkdir -p test-completions
    
    # Build temporary binary for completions
    if ! go build -o mpesa-cli-temp . >/dev/null 2>&1; then
        log_fail "Failed to build binary for completions"
        return 1
    fi
    
    # Test each completion type
    local completion_types=("bash" "zsh" "fish" "powershell")
    
    for comp_type in "${completion_types[@]}"; do
        if ./mpesa-cli-temp completion $comp_type > test-completions/mpesa-cli.$comp_type 2>/dev/null; then
            if [[ -s test-completions/mpesa-cli.$comp_type ]]; then
                log_success "Generated $comp_type completion successfully"
            else
                log_fail "$comp_type completion file is empty"
            fi
        else
            log_fail "Failed to generate $comp_type completion"
        fi
    done
    
    rm -f mpesa-cli-temp
}

test_docker_build() {
    log_test "Testing Docker build..."
    
    if ! command -v docker >/dev/null 2>&1; then
        log_warn "Docker not available - skipping Docker tests"
        return 0
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        log_warn "Docker daemon not running - skipping Docker tests"
        return 0
    fi
    
    # Test Docker build
    log_info "Building Docker image..."
    if docker build -t mpesa-cli-test:latest . >/dev/null 2>&1; then
        log_success "Docker build successful"
    else
        log_fail "Docker build failed"
        return 1
    fi
    
    # Test Docker run
    log_info "Testing Docker image execution..."
    if docker run --rm mpesa-cli-test:latest --version >/dev/null 2>&1; then
        log_success "Docker image execution test passed"
    else
        log_fail "Docker image execution test failed"
    fi
}

test_goreleaser_config() {
    log_test "Testing GoReleaser configuration..."
    
    # Check if .goreleaser.yaml exists
    if [[ ! -f .goreleaser.yaml ]]; then
        log_fail ".goreleaser.yaml not found"
        return 1
    fi
    
    # Basic YAML syntax check using built-in tools
    if command -v python3 >/dev/null 2>&1; then
        if python3 -c "import yaml; yaml.safe_load(open('.goreleaser.yaml'))" 2>/dev/null; then
            log_success "GoReleaser YAML syntax is valid"
        else
            log_fail "GoReleaser YAML syntax is invalid"
            return 1
        fi
    elif command -v yq >/dev/null 2>&1; then
        if yq eval . .goreleaser.yaml >/dev/null 2>&1; then
            log_success "GoReleaser YAML syntax is valid"
        else
            log_fail "GoReleaser YAML syntax is invalid"
            return 1
        fi
    else
        log_warn "No YAML validator found - skipping syntax check"
    fi
    
    # Check for required sections
    local required_sections=("project_name" "builds" "archives")
    
    for section in "${required_sections[@]}"; do
        if grep -q "^$section:" .goreleaser.yaml; then
            log_success "Required section '$section' found"
        else
            log_fail "Required section '$section' missing"
        fi
    done
    
    # Check for proper SBOM configuration
    if grep -q "sboms:" .goreleaser.yaml; then
        if grep -q "_sbom\.json" .goreleaser.yaml; then
            log_success "SBOM configuration looks correct"
        else
            log_warn "SBOM filename format might cause issues (should end with .json not .spdx.json)"
        fi
    fi
}

test_github_workflows() {
    log_test "Testing GitHub Actions workflows..."
    
    local workflow_dir=".github/workflows"
    
    if [[ ! -d "$workflow_dir" ]]; then
        log_fail "GitHub workflows directory not found"
        return 1
    fi
    
    # Check for required workflows
    local required_workflows=("release.yml" "test.yml")
    
    for workflow in "${required_workflows[@]}"; do
        if [[ -f "$workflow_dir/$workflow" ]]; then
            log_success "Workflow $workflow found"
            
            # Basic YAML syntax check
            if command -v python3 >/dev/null 2>&1; then
                if python3 -c "import yaml; yaml.safe_load(open('$workflow_dir/$workflow'))" 2>/dev/null; then
                    log_success "Workflow $workflow has valid YAML syntax"
                else
                    log_fail "Workflow $workflow has invalid YAML syntax"
                fi
            fi
            
            # Check for proper Go version
            if grep -q "go-version.*1\.24" "$workflow_dir/$workflow"; then
                log_success "Workflow $workflow uses correct Go version"
            else
                log_warn "Workflow $workflow might not use Go 1.24"
            fi
            
        else
            log_fail "Required workflow $workflow not found"
        fi
    done
}

test_repository_access() {
    log_test "Testing repository access..."
    
    if ! command -v gh >/dev/null 2>&1; then
        log_warn "GitHub CLI not available - skipping repository access tests"
        return 0
    fi
    
    # Check GitHub CLI authentication
    if ! gh auth status >/dev/null 2>&1; then
        log_warn "GitHub CLI not authenticated - skipping repository access tests"
        return 0
    fi
    
    # Check access to package repositories
    local repos=("homebrew-tap" "scoop-bucket")
    
    for repo in "${repos[@]}"; do
        if gh repo view "$GITHUB_USER/$repo" >/dev/null 2>&1; then
            log_success "Repository $GITHUB_USER/$repo is accessible"
        else
            log_warn "Repository $GITHUB_USER/$repo not found or not accessible"
            log_info "Run './scripts/setup-release-infrastructure.sh' to create it"
        fi
    done
}

test_secrets_setup() {
    log_test "Testing secrets configuration..."
    
    if ! command -v gh >/dev/null 2>&1; then
        log_warn "GitHub CLI not available - skipping secrets check"
        return 0
    fi
    
    if ! gh auth status >/dev/null 2>&1; then
        log_warn "GitHub CLI not authenticated - skipping secrets check"
        return 0
    fi
    
    # Check for required secrets
    local required_secrets=("PERSONAL_ACCESS_TOKEN")
    
    for secret in "${required_secrets[@]}"; do
        if gh secret list | grep -q "^$secret"; then
            log_success "Secret $secret is configured"
        else
            log_warn "Secret $secret is not configured"
            log_info "Add it at: https://github.com/$GITHUB_USER/$PROJECT_NAME/settings/secrets/actions"
        fi
    done
}

run_all_tests() {
    # Set up cleanup trap
    trap cleanup EXIT
    
    banner
    
    check_prerequisites
    check_git_status
    check_existing_tags
    
    echo
    log_step "Running pipeline tests..."
    echo
    
    test_go_modules
    test_go_build
    test_completions_generation
    test_docker_build
    test_goreleaser_config
    test_github_workflows
    test_repository_access
    test_secrets_setup
}

show_summary() {
    echo
    echo -e "${BOLD}${CYAN}================================================${NC}"
    echo -e "${BOLD}${CYAN}  Test Results Summary${NC}"
    echo -e "${BOLD}${CYAN}================================================${NC}"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed! ($TESTS_PASSED/$((TESTS_PASSED + TESTS_FAILED)))${NC}"
        echo
        echo -e "${GREEN}✅ Your pipeline is ready for release!${NC}"
        echo
        echo "Next steps:"
        echo "1. Commit your changes:"
        echo "   git add ."
        echo "   git commit -m 'Apply working pipeline configurations'"
        echo
        echo "2. Push to GitHub:"
        echo "   git push origin $(git branch --show-current)"
        echo
        echo "3. Create and push a test tag:"
        echo "   git tag v1.0.1-test"
        echo "   git push origin v1.0.1-test"
        echo
        echo "4. Monitor the workflow at:"
        echo "   https://github.com/$GITHUB_USER/$PROJECT_NAME/actions"
        
    else
        echo -e "${RED}❌ Some tests failed ($TESTS_FAILED failed, $TESTS_PASSED passed)${NC}"
        echo
        echo -e "${RED}Failed tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  - $test"
        done
        echo
        echo -e "${YELLOW}Please fix the issues above before proceeding with the release.${NC}"
    fi
    
    echo
}

# Main execution
main() {
    case "${1:-}" in
        --help|-h)
            echo "Usage: $0 [--help]"
            echo ""
            echo "Local pipeline testing script for $PROJECT_NAME"
            echo ""
            echo "This script validates:"
            echo "  - Go build and cross-compilation"
            echo "  - Go modules integrity"
            echo "  - Completions generation" 
            echo "  - Docker build (if available)"
            echo "  - GoReleaser configuration"
            echo "  - GitHub Actions workflows"
            echo "  - Repository access and secrets"
            echo ""
            echo "Options:"
            echo "  --help       Show this help message"
            exit 0
            ;;
        "")
            run_all_tests
            show_summary
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"