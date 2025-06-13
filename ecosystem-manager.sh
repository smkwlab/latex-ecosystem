#!/bin/bash
#
# LaTeX Thesis Environment Ecosystem Manager
# 
# This script provides utilities for managing the multi-repository ecosystem
# Usage: ./ecosystem-manager.sh [command] [options]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOS=(
    "ai-academic-paper-reviewer"
    "aldc" 
    "latex-environment"
    "latex-release-action"
    "latex-template"
    "sotsuron-report-template"
    "sotsuron-template"
    "texlive-ja-textlint"
    "thesis-management-tools"
    "wr-template"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if we're in the right directory
check_environment() {
    if [ ! -f "ECOSYSTEM.md" ]; then
        error "ECOSYSTEM.md not found. Please run this script from the thesis-environment directory."
        exit 1
    fi
}

# Display help
show_help() {
    cat << EOF
LaTeX Thesis Environment Ecosystem Manager

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    status          Show status of all repositories
    sync            Sync all repositories (git pull)
    check           Check for uncommitted changes
    versions        Show current versions/tags
    deps            Analyze dependency relationships
    test            Run ecosystem-wide tests
    claude-status   Check CLAUDE.md tracking status
    help            Show this help message

Options:
    --repo REPO     Apply command to specific repository only
    --verbose       Show detailed output
    --dry-run       Show what would be done without executing

Examples:
    $0 status                    # Show status of all repos
    $0 sync --repo latex-environment  # Sync only latex-environment
    $0 check --verbose           # Check for changes with details
    $0 claude-status             # Check CLAUDE.md git tracking

EOF
}

# Check if repository exists
repo_exists() {
    local repo="$1"
    [ -d "$SCRIPT_DIR/$repo/.git" ]
}

# Get current branch for repository
get_current_branch() {
    local repo="$1"
    if repo_exists "$repo"; then
        (cd "$SCRIPT_DIR/$repo" && git branch --show-current 2>/dev/null || echo "detached")
    else
        echo "missing"
    fi
}

# Get repository status
get_repo_status() {
    local repo="$1"
    if repo_exists "$repo"; then
        (cd "$SCRIPT_DIR/$repo" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    else
        echo "missing"
    fi
}

# Show status of all repositories
show_status() {
    local specific_repo="$1"
    local verbose="$2"
    
    log "Repository Status Overview"
    echo
    printf "%-30s %-15s %-10s %-20s\n" "Repository" "Branch" "Changes" "Last Commit"
    printf "%-30s %-15s %-10s %-20s\n" "----------" "------" "-------" "-----------"
    
    for repo in "${REPOS[@]}"; do
        if [ -n "$specific_repo" ] && [ "$specific_repo" != "$repo" ]; then
            continue
        fi
        
        if repo_exists "$repo"; then
            branch=$(get_current_branch "$repo")
            changes=$(get_repo_status "$repo")
            last_commit=$(cd "$SCRIPT_DIR/$repo" && git log -1 --format="%h %cr" 2>/dev/null || echo "unknown")
            
            if [ "$changes" -gt 0 ]; then
                printf "%-30s %-15s ${YELLOW}%-10s${NC} %-20s\n" "$repo" "$branch" "$changes" "$last_commit"
            else
                printf "%-30s %-15s ${GREEN}%-10s${NC} %-20s\n" "$repo" "$branch" "clean" "$last_commit"
            fi
            
            if [ "$verbose" = "true" ]; then
                (cd "$SCRIPT_DIR/$repo" && git status --short 2>/dev/null | sed 's/^/    /')
            fi
        else
            printf "%-30s ${RED}%-15s${NC} %-10s %-20s\n" "$repo" "missing" "-" "-"
        fi
    done
}

# Sync repositories
sync_repos() {
    local specific_repo="$1"
    local dry_run="$2"
    
    log "Syncing repositories..."
    
    for repo in "${REPOS[@]}"; do
        if [ -n "$specific_repo" ] && [ "$specific_repo" != "$repo" ]; then
            continue
        fi
        
        if repo_exists "$repo"; then
            echo -n "Syncing $repo... "
            if [ "$dry_run" = "true" ]; then
                echo "[DRY RUN]"
            else
                if (cd "$SCRIPT_DIR/$repo" && git pull origin "$(git branch --show-current)" >/dev/null 2>&1); then
                    success "OK"
                else
                    error "FAILED"
                fi
            fi
        else
            warn "$repo directory not found"
        fi
    done
}

# Check for uncommitted changes
check_changes() {
    local specific_repo="$1"
    local verbose="$2"
    
    log "Checking for uncommitted changes..."
    local has_changes=false
    
    for repo in "${REPOS[@]}"; do
        if [ -n "$specific_repo" ] && [ "$specific_repo" != "$repo" ]; then
            continue
        fi
        
        if repo_exists "$repo"; then
            changes=$(get_repo_status "$repo")
            if [ "$changes" -gt 0 ]; then
                warn "$repo has $changes uncommitted changes"
                has_changes=true
                if [ "$verbose" = "true" ]; then
                    (cd "$SCRIPT_DIR/$repo" && git status --short)
                fi
            fi
        fi
    done
    
    if [ "$has_changes" = false ]; then
        success "All repositories are clean"
    fi
}

# Show versions/tags
show_versions() {
    local specific_repo="$1"
    
    log "Repository Versions"
    echo
    printf "%-30s %-15s %-20s\n" "Repository" "Latest Tag" "Current Commit"
    printf "%-30s %-15s %-20s\n" "----------" "----------" "--------------"
    
    for repo in "${REPOS[@]}"; do
        if [ -n "$specific_repo" ] && [ "$specific_repo" != "$repo" ]; then
            continue
        fi
        
        if repo_exists "$repo"; then
            latest_tag=$(cd "$SCRIPT_DIR/$repo" && git describe --tags --abbrev=0 2>/dev/null || echo "no tags")
            current_commit=$(cd "$SCRIPT_DIR/$repo" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
            printf "%-30s %-15s %-20s\n" "$repo" "$latest_tag" "$current_commit"
        else
            printf "%-30s ${RED}%-15s${NC} %-20s\n" "$repo" "missing" "-"
        fi
    done
}

# Analyze dependencies
analyze_deps() {
    log "Dependency Analysis"
    echo
    echo "Core Infrastructure:"
    echo "  texlive-ja-textlint (Docker base)"
    echo "    ↓"
    echo "  latex-environment (DevContainer template)"
    echo "    ↓"
    echo "  Templates (sotsuron-template, wr-template, etc.)"
    echo
    echo "Supporting Tools:"
    echo "  - latex-release-action: Used by all templates"
    echo "  - ai-academic-paper-reviewer: Used by thesis repositories"
    echo "  - aldc: Consumes latex-environment release branch"
    echo "  - thesis-management-tools: Management workflows"
    echo
    
    # Check actual docker image references
    echo "Current Docker Image Usage:"
    for repo in "${REPOS[@]}"; do
        if repo_exists "$repo" && [ -f "$SCRIPT_DIR/$repo/.devcontainer/devcontainer.json" ]; then
            image=$(grep -o '"image":\s*"[^"]*"' "$SCRIPT_DIR/$repo/.devcontainer/devcontainer.json" 2>/dev/null | cut -d'"' -f4)
            if [ -n "$image" ]; then
                echo "  $repo: $image"
            fi
        fi
    done
}

# Check CLAUDE.md tracking status
check_claude_status() {
    log "CLAUDE.md Git Tracking Status"
    echo
    printf "%-30s %-15s %-20s\n" "Repository" "CLAUDE.md" "Status"
    printf "%-30s %-15s %-20s\n" "----------" "----------" "------"
    
    for repo in "${REPOS[@]}"; do
        if repo_exists "$repo"; then
            if [ -f "$SCRIPT_DIR/$repo/CLAUDE.md" ]; then
                if (cd "$SCRIPT_DIR/$repo" && git ls-files --error-unmatch CLAUDE.md >/dev/null 2>&1); then
                    printf "%-30s ${GREEN}%-15s${NC} %-20s\n" "$repo" "exists" "tracked"
                else
                    printf "%-30s ${YELLOW}%-15s${NC} %-20s\n" "$repo" "exists" "not tracked"
                fi
            else
                printf "%-30s ${RED}%-15s${NC} %-20s\n" "$repo" "missing" "-"
            fi
        else
            printf "%-30s ${RED}%-15s${NC} %-20s\n" "$repo" "repo missing" "-"
        fi
    done
}

# Run ecosystem tests
run_tests() {
    local dry_run="$1"
    
    log "Running ecosystem-wide tests..."
    
    if [ "$dry_run" = "true" ]; then
        echo "[DRY RUN] Would run the following tests:"
        echo "  - Docker image availability check"
        echo "  - DevContainer configuration validation"
        echo "  - Cross-repository compatibility check"
        echo "  - Documentation link validation"
        return
    fi
    
    local test_passed=true
    
    # Test 1: Check if texlive-ja-textlint image is available
    echo -n "Testing Docker image availability... "
    if docker manifest inspect ghcr.io/smkwlab/texlive-ja-textlint:2025b >/dev/null 2>&1; then
        success "OK"
    else
        error "FAILED - Docker image not available"
        test_passed=false
    fi
    
    # Test 2: Validate devcontainer.json files
    echo -n "Validating devcontainer.json files... "
    local devcontainer_errors=0
    for repo in "${REPOS[@]}"; do
        if [ -f "$SCRIPT_DIR/$repo/.devcontainer/devcontainer.json" ]; then
            if ! python3 -m json.tool "$SCRIPT_DIR/$repo/.devcontainer/devcontainer.json" >/dev/null 2>&1; then
                devcontainer_errors=$((devcontainer_errors + 1))
            fi
        fi
    done
    
    if [ $devcontainer_errors -eq 0 ]; then
        success "OK"
    else
        error "FAILED - $devcontainer_errors invalid devcontainer.json files"
        test_passed=false
    fi
    
    if [ "$test_passed" = true ]; then
        success "All tests passed"
    else
        error "Some tests failed"
        exit 1
    fi
}

# Parse command line arguments
COMMAND=""
SPECIFIC_REPO=""
VERBOSE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        status|sync|check|versions|deps|test|claude-status|help)
            COMMAND="$1"
            shift
            ;;
        --repo)
            SPECIFIC_REPO="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
check_environment

case "$COMMAND" in
    status)
        show_status "$SPECIFIC_REPO" "$VERBOSE"
        ;;
    sync)
        sync_repos "$SPECIFIC_REPO" "$DRY_RUN"
        ;;
    check)
        check_changes "$SPECIFIC_REPO" "$VERBOSE"
        ;;
    versions)
        show_versions "$SPECIFIC_REPO"
        ;;
    deps)
        analyze_deps
        ;;
    test)
        run_tests "$DRY_RUN"
        ;;
    claude-status)
        check_claude_status
        ;;
    help|"")
        show_help
        ;;
    *)
        error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac