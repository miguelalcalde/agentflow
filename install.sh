#!/usr/bin/env bash
#
# Agent Workflow Installer
# Installs the multi-agent workflow system in your project
#
# Usage:
#   Remote install:
#     curl -fsSL https://raw.githubusercontent.com/miguelalcalde/agentworkflow/main/install.sh | bash
#
#   Local install (for testing):
#     ./install.sh                     # Install in current directory using remote templates
#     ./install.sh /path/to/project    # Install in target directory using remote templates
#     ./install.sh --local             # Install in current directory using local templates
#     ./install.sh --local /path/to/project  # Install in target directory using local templates
#

set -euo pipefail

# Configuration
REPO="miguelalcalde/agentworkflow"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"

# Script location (for local mode)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Defaults
LOCAL_MODE=false
TARGET_DIR="."

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --local|-l)
            LOCAL_MODE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--local] [target_directory]"
            echo ""
            echo "Options:"
            echo "  --local, -l    Use local templates instead of downloading from GitHub"
            echo "  --help, -h     Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                      # Install in current directory (remote)"
            echo "  $0 /path/to/project     # Install in target directory (remote)"
            echo "  $0 --local              # Install using local templates"
            echo "  $0 --local ../myproject # Install in target using local templates"
            exit 0
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# Check required tools
check_requirements() {
    local missing=()
    
    for cmd in mkdir sed; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ "$LOCAL_MODE" == false ]]; then
        if ! command -v curl &> /dev/null; then
            missing+=("curl")
        fi
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        exit 1
    fi
}

# Cross-platform sed -i (macOS vs Linux)
sed_inplace() {
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Download a file with error handling
download_file() {
    local url="$1"
    local dest="$2"
    local temp_file
    temp_file=$(mktemp)
    
    if ! curl -fsSL "$url" -o "$temp_file" 2>/dev/null; then
        rm -f "$temp_file"
        log_error "Failed to download: $url"
        return 1
    fi
    
    # Verify download is not empty and not an error page
    if [[ ! -s "$temp_file" ]]; then
        rm -f "$temp_file"
        log_error "Downloaded empty file: $url"
        return 1
    fi
    
    # Check for GitHub 404 response (HTML)
    if head -1 "$temp_file" | grep -qi "<!DOCTYPE\|<html"; then
        rm -f "$temp_file"
        log_error "Received HTML instead of file (likely 404): $url"
        return 1
    fi
    
    mv "$temp_file" "$dest"
    return 0
}

# Copy a file from local templates
copy_local_file() {
    local src="$1"
    local dest="$2"
    
    if [[ ! -f "$src" ]]; then
        log_error "Local template not found: $src"
        return 1
    fi
    
    cp "$src" "$dest"
    return 0
}

# Get file (download or copy based on mode)
get_file() {
    local remote_path="$1"
    local dest="$2"
    
    if [[ "$LOCAL_MODE" == true ]]; then
        copy_local_file "$SCRIPT_DIR/$remote_path" "$dest"
    else
        download_file "$BASE_URL/$remote_path" "$dest"
    fi
}

check_requirements

# Resolve target directory
if [[ "$TARGET_DIR" != "." ]]; then
    if [[ ! -d "$TARGET_DIR" ]]; then
        log_error "Target directory does not exist: $TARGET_DIR"
        exit 1
    fi
    cd "$TARGET_DIR"
fi

log_info "Installing agent workflow in: $(pwd)"

if [[ "$LOCAL_MODE" == true ]]; then
    log_info "Using local templates from: $SCRIPT_DIR"
fi

# Check for existing installation
if [[ -d ".workflow" ]]; then
    log_warn ".workflow directory already exists"
    # If running non-interactively (piped), skip prompt
    if [[ -t 0 ]]; then
        read -p "Overwrite existing installation? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled"
            exit 0
        fi
    else
        log_warn "Running non-interactively, backing up existing .workflow to .workflow.bak"
        rm -rf .workflow.bak
        mv .workflow .workflow.bak
    fi
fi

# Create directory structure
log_info "Creating directory structure..."
mkdir -p .workflow/prds
mkdir -p .workflow/plans
mkdir -p .claude/agents      # Claude Code agents (project-level)
mkdir -p .cursor/agents      # Cursor agents (project-level)
mkdir -p .cursor/rules
mkdir -p "$HOME/.cursor/skills/feature-workflow"  # Cursor skills (user-level)

# Track failures
FAILURES=0

# Download/copy workflow templates
log_info "Getting workflow templates..."
get_file "templates/workflow/config.yaml" ".workflow/config.yaml" || ((FAILURES++))
get_file "templates/workflow/backlog.md" ".workflow/backlog.md" || ((FAILURES++))
get_file "templates/workflow/questions.md" ".workflow/questions.md" || ((FAILURES++))
get_file "templates/workflow/action-log.md" ".workflow/action-log.md" || ((FAILURES++))
touch .workflow/prds/.gitkeep
touch .workflow/plans/.gitkeep

# Download/copy agent definitions
# Install to BOTH .claude/agents (Claude Code) AND .cursor/agents (Cursor)
log_info "Getting agent definitions..."
for agent in picker planner refiner implementer conductor; do
    get_file "templates/claude-agents/$agent.md" ".claude/agents/$agent.md" || ((FAILURES++))
    cp ".claude/agents/$agent.md" ".cursor/agents/$agent.md" 2>/dev/null || true
done

# Download/copy Cursor rules
log_info "Getting Cursor rules..."
get_file "templates/cursor-rules/workflow-agents.mdc" ".cursor/rules/workflow-agents.mdc" || ((FAILURES++))

# Download/copy Cursor skill (user-level)
log_info "Installing Cursor skill to ~/.cursor/skills/..."
get_file "templates/cursor-skills/feature-workflow/SKILL.md" "$HOME/.cursor/skills/feature-workflow/SKILL.md" || ((FAILURES++))

# Check for failures
if [[ $FAILURES -gt 0 ]]; then
    log_error "$FAILURES file(s) failed to download/copy"
    log_error "Installation incomplete. Please check the errors above."
    exit 1
fi

log_success "All files downloaded successfully"

# Try to detect project info for config customization
PROJECT_NAME=$(basename "$(pwd)")

# Detect project type and configure commands
detect_project() {
    local test_cmd=""
    local lint_cmd=""
    local build_cmd=""
    
    if [[ -f "package.json" ]]; then
        log_info "Detected Node.js project"
        
        # Try to read project name
        local detected_name
        detected_name=$(grep -o '"name":[[:space:]]*"[^"]*"' package.json 2>/dev/null | head -1 | cut -d'"' -f4 || echo "")
        if [[ -n "$detected_name" ]]; then
            PROJECT_NAME="$detected_name"
        fi
        
        # Detect test command
        if grep -q '"test"' package.json 2>/dev/null; then
            test_cmd="npm test"
        fi
        
        # Detect lint command
        if grep -q '"lint"' package.json 2>/dev/null; then
            lint_cmd="npm run lint"
        elif grep -q '"check"' package.json 2>/dev/null; then
            lint_cmd="npm run check"
        fi
        
        # Detect build command
        if grep -q '"build"' package.json 2>/dev/null; then
            build_cmd="npm run build"
        fi
        
    elif [[ -f "bun.lockb" ]] || [[ -f "bun.lock" ]]; then
        log_info "Detected Bun project"
        test_cmd="bun test"
        lint_cmd="bun run lint"
        build_cmd="bun run build"
        
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        log_info "Detected Python project"
        if [[ -f "pyproject.toml" ]]; then
            test_cmd="pytest"
            lint_cmd="ruff check ."
        else
            test_cmd="pytest"
            lint_cmd="flake8"
        fi
        
    elif [[ -f "go.mod" ]]; then
        log_info "Detected Go project"
        test_cmd="go test ./..."
        lint_cmd="golangci-lint run"
        build_cmd="go build ./..."
        
    elif [[ -f "Cargo.toml" ]]; then
        log_info "Detected Rust project"
        test_cmd="cargo test"
        lint_cmd="cargo clippy"
        build_cmd="cargo build"
        
    elif [[ -f "Makefile" ]]; then
        log_info "Detected project with Makefile"
        if grep -q '^test:' Makefile 2>/dev/null; then
            test_cmd="make test"
        fi
        if grep -q '^lint:' Makefile 2>/dev/null; then
            lint_cmd="make lint"
        fi
        if grep -q '^build:' Makefile 2>/dev/null; then
            build_cmd="make build"
        fi
    fi
    
    # Update config with detected commands (only if detected)
    if [[ -n "$test_cmd" ]]; then
        sed_inplace "s|test: \"npm test\"|test: \"$test_cmd\"|" .workflow/config.yaml 2>/dev/null || true
    fi
    if [[ -n "$lint_cmd" ]]; then
        sed_inplace "s|lint: \"npm run lint\"|lint: \"$lint_cmd\"|" .workflow/config.yaml 2>/dev/null || true
    fi
    if [[ -n "$build_cmd" ]]; then
        sed_inplace "s|build: \"npm run build\"|build: \"$build_cmd\"|" .workflow/config.yaml 2>/dev/null || true
    fi
}

detect_project

# Update config with project name
sed_inplace "s|name: \"My Project\"|name: \"$PROJECT_NAME\"|" .workflow/config.yaml 2>/dev/null || true

echo ""
log_success "Agent workflow installed successfully!"
echo ""
echo "Directory structure created:"
echo "  .workflow/              - Workflow state files"
echo "  .claude/agents/         - Claude Code agent definitions"
echo "  .cursor/agents/         - Cursor agent definitions"
echo "  .cursor/rules/          - Cursor workflow rules"
echo "  ~/.cursor/skills/       - Cursor skills (user-level)"
echo ""
echo "Agents installed: picker, planner, refiner, implementer, conductor"
echo ""
echo "Next steps:"
echo "  1. Edit .workflow/config.yaml to verify/customize commands"
echo "  2. Add tasks to .workflow/backlog.md"
echo "  3. Use one of:"
echo "     - Claude Code: claude \"Use the picker agent to start\""
echo "     - Cursor: /pick or /conduct"
echo ""
echo "Documentation: https://github.com/$REPO"
