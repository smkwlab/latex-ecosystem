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
    --long, -l      Show detailed PR/Issue information (default: compact)
    --urgent-issues Show only repositories with urgent issues
    --with-prs      Show only repositories with open PRs
    --needs-review  Show only repositories with PRs needing review
    --dry-run       Show what would be done without executing

Format Legend (compact mode):
    PRs: number(dr) - d=drafts, r=needs review
    Issues: number(bf!) - b=bugs, f=features, !=urgent

Examples:
    $0 status                    # Show compact status of all repos
    $0 status --long             # Show detailed status with full descriptions  
    $0 status --urgent-issues    # Show only repos with urgent issues
    $0 status --with-prs         # Show only repos with open PRs
    $0 status --needs-review     # Show only repos with PRs needing review
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

# Truncate string to specified length with ellipsis
truncate_string() {
    local str="$1"
    local max_length="$2"
    local ellipsis="..."
    
    if [ ${#str} -le $max_length ]; then
        echo "$str"
    else
        local truncated_length=$((max_length - ${#ellipsis}))
        echo "${str:0:$truncated_length}$ellipsis"
    fi
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

# Get repository issue status
get_issue_status() {
    local repo="$1"
    if repo_exists "$repo" && command -v gh >/dev/null 2>&1; then
        (cd "$SCRIPT_DIR/$repo" && {
            # Get issues with labels for categorization
            issues_json=$(gh issue list --state open --json number,title,labels,createdAt 2>/dev/null || echo "[]")
            
            if [ "$issues_json" = "[]" ] || [ -z "$issues_json" ]; then
                echo "0|0|0|0"
                return
            fi
            
            # Count total issues
            total=$(echo "$issues_json" | jq -r 'length' 2>/dev/null || echo "0")
            
            # Count by type (based on labels)
            bugs=$(echo "$issues_json" | jq -r '[.[] | select(.labels[]?.name | test("bug|error|critical|regression"; "i"))] | length' 2>/dev/null || echo "0")
            enhancements=$(echo "$issues_json" | jq -r '[.[] | select(.labels[]?.name | test("enhancement|feature|improvement|request"; "i"))] | length' 2>/dev/null || echo "0")
            urgent=$(echo "$issues_json" | jq -r '[.[] | select(.labels[]?.name | test("critical|urgent|high"; "i"))] | length' 2>/dev/null || echo "0")
            
            echo "$total|$bugs|$enhancements|$urgent"
        })
    else
        echo "0|0|0|0"
    fi
}

# Get repository PR status
get_pr_status() {
    local repo="$1"
    if repo_exists "$repo" && command -v gh >/dev/null 2>&1; then
        (cd "$SCRIPT_DIR/$repo" && {
            # Get PR information with review status
            pr_json=$(gh pr list --state open --json number,title,isDraft,reviewDecision,labels 2>/dev/null || echo "[]")
            
            if [ "$pr_json" = "[]" ] || [ -z "$pr_json" ]; then
                echo "0|0|0"
                return
            fi
            
            # Count total PRs
            total=$(echo "$pr_json" | jq -r 'length' 2>/dev/null || echo "0")
            
            # Count draft PRs
            drafts=$(echo "$pr_json" | jq -r '[.[] | select(.isDraft == true)] | length' 2>/dev/null || echo "0")
            
            # Count PRs needing review (not draft and no approval yet)
            needs_review=$(echo "$pr_json" | jq -r '[.[] | select(.isDraft == false and (.reviewDecision == null or .reviewDecision == "REVIEW_REQUIRED"))] | length' 2>/dev/null || echo "0")
            
            echo "$total|$drafts|$needs_review"
        })
    else
        echo "0|0|0"
    fi
}

# Format PR information for display
format_pr_info() {
    local pr_data="$1"
    local long_format="$2"
    IFS='|' read -r total drafts needs_review <<< "$pr_data"
    
    if [ "$total" -eq 0 ]; then
        echo "0"
        return
    fi
    
    if [ "$long_format" = "true" ]; then
        local details=""
        
        # Build details string for long format
        if [ "$drafts" -gt 0 ] && [ "$needs_review" -gt 0 ]; then
            details="$drafts draft"
            [ "$drafts" -gt 1 ] && details="${details}s"
            details="${details}, $needs_review need"
            [ "$needs_review" -gt 1 ] && details="${details}" || details="${details}s"
            details="${details} review"
        elif [ "$drafts" -gt 0 ]; then
            details="$drafts draft"
            [ "$drafts" -gt 1 ] && details="${details}s"
        elif [ "$needs_review" -gt 0 ]; then
            details="$needs_review need"
            [ "$needs_review" -gt 1 ] && details="${details}" || details="${details}s"
            details="${details} review"
        fi
        
        if [ -n "$details" ]; then
            echo "$total open ($details)"
        else
            echo "$total open"
        fi
    else
        # Short format: just number, with markers
        local markers=""
        [ "$drafts" -gt 0 ] && markers="${markers}d"
        [ "$needs_review" -gt 0 ] && markers="${markers}r"
        
        if [ -n "$markers" ]; then
            echo "$total($markers)"
        else
            echo "$total"
        fi
    fi
}

# Format issue information for display
format_issue_info() {
    local issue_data="$1"
    local long_format="$2"
    IFS='|' read -r total bugs enhancements urgent <<< "$issue_data"
    
    if [ "$total" -eq 0 ]; then
        echo "0"
        return
    fi
    
    if [ "$long_format" = "true" ]; then
        local details=""
        local urgent_marker=""
        
        # Add urgent marker if there are urgent issues
        if [ "$urgent" -gt 0 ]; then
            urgent_marker=" 🚨"
        fi
        
        # Build details string for long format
        if [ "$bugs" -gt 0 ] && [ "$enhancements" -gt 0 ]; then
            details="$bugs bug"
            [ "$bugs" -gt 1 ] && details="${details}s"
            details="${details}, $enhancements feature"
            [ "$enhancements" -gt 1 ] && details="${details}s"
        elif [ "$bugs" -gt 0 ]; then
            details="$bugs bug"
            [ "$bugs" -gt 1 ] && details="${details}s"
        elif [ "$enhancements" -gt 0 ]; then
            details="$enhancements feature"
            [ "$enhancements" -gt 1 ] && details="${details}s"
        fi
        
        if [ -n "$details" ]; then
            echo "$total open ($details)$urgent_marker"
        else
            echo "$total open$urgent_marker"
        fi
    else
        # Short format: just number, with markers
        local markers=""
        [ "$bugs" -gt 0 ] && markers="${markers}b"
        [ "$enhancements" -gt 0 ] && markers="${markers}f"
        [ "$urgent" -gt 0 ] && markers="${markers}!"
        
        if [ -n "$markers" ]; then
            echo "$total($markers)"
        else
            echo "$total"
        fi
    fi
}

# Show status of all repositories
show_status() {
    local specific_repo="$1"
    local verbose="$2"
    
    if [ "$URGENT_ISSUES_ONLY" = "true" ]; then
        log "🚨 Repositories with Urgent Issues"
    elif [ "$WITH_PRS_ONLY" = "true" ]; then
        log "📋 Repositories with Open Pull Requests"
    elif [ "$NEEDS_REVIEW_ONLY" = "true" ]; then
        log "👁️ Repositories with PRs Needing Review"
    else
        log "Repository Status Overview"
    fi
    echo
    if [ "$LONG_FORMAT" = "true" ]; then
        printf "%-30s %-23s %-10s %-20s %-25s %-25s\n" "Repository" "Branch" "Changes" "Last Commit" "PRs" "Issues"
        printf "%-30s %-23s %-10s %-20s %-25s %-25s\n" "----------" "------" "-------" "-----------" "---" "------"
    else
        printf "%-30s %-23s %-8s %-20s %-8s %-8s\n" "Repository" "Branch" "Changes" "Last Commit" "PRs" "Issues"
        printf "%-30s %-23s %-8s %-20s %-8s %-8s\n" "----------" "------" "-------" "-----------" "---" "------"
    fi
    
    for repo in "${REPOS[@]}"; do
        if [ -n "$specific_repo" ] && [ "$specific_repo" != "$repo" ]; then
            continue
        fi
        
        if repo_exists "$repo"; then
            branch=$(get_current_branch "$repo")
            changes=$(get_repo_status "$repo")
            last_commit=$(cd "$SCRIPT_DIR/$repo" && git log -1 --format="%h %cr" 2>/dev/null || echo "unknown")
            issue_data=$(get_issue_status "$repo")
            issue_info=$(format_issue_info "$issue_data" "$LONG_FORMAT")
            pr_data=$(get_pr_status "$repo")
            pr_info=$(format_pr_info "$pr_data" "$LONG_FORMAT")
            
            # Truncate repository and branch names for display
            if [ "$LONG_FORMAT" = "true" ]; then
                repo_display=$(truncate_string "$repo" 28)
                branch_display=$(truncate_string "$branch" 21)
            else
                repo_display=$(truncate_string "$repo" 28)
                branch_display=$(truncate_string "$branch" 21)
            fi
            
            # Extract counts for filtering
            IFS='|' read -r issue_total bugs enhancements urgent <<< "$issue_data"
            IFS='|' read -r pr_total drafts needs_review <<< "$pr_data"
            
            # Apply filters
            if [ "$URGENT_ISSUES_ONLY" = "true" ] && [ "$urgent" -eq 0 ]; then
                continue
            fi
            if [ "$WITH_PRS_ONLY" = "true" ] && [ "$pr_total" -eq 0 ]; then
                continue
            fi
            if [ "$NEEDS_REVIEW_ONLY" = "true" ] && [ "$needs_review" -eq 0 ]; then
                continue
            fi
            
            if [ "$LONG_FORMAT" = "true" ]; then
                if [ "$changes" -gt 0 ]; then
                    if [ "$urgent" -gt 0 ]; then
                        printf "%-30s %-23s ${YELLOW}%-10s${NC} %-20s %-25s ${RED}%-25s${NC}\n" "$repo_display" "$branch_display" "$changes" "$last_commit" "$pr_info" "$issue_info"
                    else
                        printf "%-30s %-23s ${YELLOW}%-10s${NC} %-20s %-25s %-25s\n" "$repo_display" "$branch_display" "$changes" "$last_commit" "$pr_info" "$issue_info"
                    fi
                else
                    if [ "$urgent" -gt 0 ]; then
                        printf "%-30s %-23s ${GREEN}%-10s${NC} %-20s %-25s ${RED}%-25s${NC}\n" "$repo_display" "$branch_display" "clean" "$last_commit" "$pr_info" "$issue_info"
                    else
                        printf "%-30s %-23s ${GREEN}%-10s${NC} %-20s %-25s %-25s\n" "$repo_display" "$branch_display" "clean" "$last_commit" "$pr_info" "$issue_info"
                    fi
                fi
            else
                # Short format with fixed width columns
                if [ "$changes" -gt 0 ]; then
                    if [ "$urgent" -gt 0 ]; then
                        printf "%-30s %-23s ${YELLOW}%-8s${NC} %-20s %-8s ${RED}%-8s${NC}\n" "$repo_display" "$branch_display" "$changes" "$last_commit" "$pr_info" "$issue_info"
                    else
                        printf "%-30s %-23s ${YELLOW}%-8s${NC} %-20s %-8s %-8s\n" "$repo_display" "$branch_display" "$changes" "$last_commit" "$pr_info" "$issue_info"
                    fi
                else
                    if [ "$urgent" -gt 0 ]; then
                        printf "%-30s %-23s ${GREEN}%-8s${NC} %-20s %-8s ${RED}%-8s${NC}\n" "$repo_display" "$branch_display" "clean" "$last_commit" "$pr_info" "$issue_info"
                    else
                        printf "%-30s %-23s ${GREEN}%-8s${NC} %-20s %-8s %-8s\n" "$repo_display" "$branch_display" "clean" "$last_commit" "$pr_info" "$issue_info"
                    fi
                fi
            fi
            
            if [ "$verbose" = "true" ]; then
                (cd "$SCRIPT_DIR/$repo" && git status --short 2>/dev/null | sed 's/^/    /')
            fi
        else
            # Truncate repository name for missing repos too
            repo_display=$(truncate_string "$repo" 28)
            
            if [ "$LONG_FORMAT" = "true" ]; then
                printf "%-30s ${RED}%-23s${NC} %-10s %-20s %-25s %-25s\n" "$repo_display" "missing" "-" "-" "-" "-"
            else
                printf "%-30s ${RED}%-23s${NC} %-8s %-20s %-8s %-8s\n" "$repo_display" "missing" "-" "-" "-" "-"
            fi
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
URGENT_ISSUES_ONLY=false
WITH_PRS_ONLY=false
NEEDS_REVIEW_ONLY=false
LONG_FORMAT=false

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
        --long|-l)
            LONG_FORMAT=true
            shift
            ;;
        --urgent-issues)
            URGENT_ISSUES_ONLY=true
            shift
            ;;
        --with-prs)
            WITH_PRS_ONLY=true
            shift
            ;;
        --needs-review)
            NEEDS_REVIEW_ONLY=true
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