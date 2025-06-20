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
    "."                          # Management repository (latex-ecosystem)
    "texlive-ja-textlint"
    "latex-environment"
    "aldc"
    "sotsuron-template"
    "latex-template"
    "sotsuron-report-template"
    "wr-template"
    "ise-report-template"
    "latex-release-action"
    "thesis-management-tools"
    "ai-academic-paper-reviewer"
)

# Cache configuration
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ecosystem-manager"
CACHE_DURATION=300  # 5 minutes
DEFAULT_CACHE_ENABLED=true

# Performance configuration
RATE_LIMIT_WARNING_THRESHOLD=50
RATE_LIMIT_ERROR_THRESHOLD=5
MAX_PARALLEL_JOBS=3

# Display configuration (make hardcoded values configurable)
readonly REPO_COLUMN_WIDTH=24
readonly BRANCH_COLUMN_WIDTH=25

# Error handling configuration
readonly GITHUB_API_TIMEOUT=10
readonly MAX_RETRIES=3

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
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if GitHub CLI is authenticated and available
check_github_cli() {
    if ! command -v gh >/dev/null 2>&1; then
        return 1
    fi
    
    # Check authentication status - look for active account
    local auth_output
    auth_output=$(gh auth status 2>&1)
    if ! echo "$auth_output" | grep -q "Active account: true"; then
        warn "GitHub CLI has no active authenticated account. Some features may not work properly."
        warn "Run 'gh auth login' to authenticate."
        return 1
    fi
    
    return 0
}

# Robust jq parsing with error handling
safe_jq() {
    local json="$1"
    local query="$2"
    local default_value="${3:-0}"
    
    if [ -z "$json" ] || [ "$json" = "[]" ] || [ "$json" = "null" ]; then
        echo "$default_value"
        return
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        warn "jq command not found. Install jq for full functionality."
        echo "$default_value"
        return
    fi
    
    local result
    if ! result=$(echo "$json" | jq -r "$query" 2>/dev/null) || [ -z "$result" ] || [ "$result" = "null" ]; then
        echo "$default_value"
    else
        echo "$result"
    fi
}

# Execute GitHub CLI command with retry and timeout
github_api_call() {
    local cmd="$1"
    local retries=0
    local result
    
    while [ $retries -lt $MAX_RETRIES ]; do
        if result=$(timeout "$GITHUB_API_TIMEOUT" bash -c "$cmd" 2>/dev/null) && [ -n "$result" ]; then
            echo "$result"
            return 0
        fi
        
        retries=$((retries + 1))
        if [ $retries -lt $MAX_RETRIES ]; then
            sleep 1
        fi
    done
    
    # Return empty JSON array on failure
    echo "[]"
    return 1
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

# Initialize cache directory
init_cache() {
    if [ "$CACHE_ENABLED" = "true" ]; then
        mkdir -p "$CACHE_DIR"
    fi
}

# Check GitHub API rate limit
check_rate_limit() {
    if ! command -v gh >/dev/null 2>&1; then
        return 0  # No gh CLI, skip rate limit check
    fi
    
    local rate_info
    rate_info=$(gh api rate_limit --jq '.resources.core | {remaining: .remaining, reset: .reset}' 2>/dev/null || echo '{"remaining": "unknown", "reset": 0}')
    
    local remaining
    remaining=$(echo "$rate_info" | jq -r '.remaining' 2>/dev/null || echo "unknown")
    local reset_time
    reset_time=$(echo "$rate_info" | jq -r '.reset' 2>/dev/null || echo "0")
    
    if [ "$remaining" != "unknown" ] && [ "$remaining" -lt "$RATE_LIMIT_WARNING_THRESHOLD" ]; then
        local reset_date
        reset_date=$(date -d "@$reset_time" 2>/dev/null || echo "unknown")
        warn "GitHub API rate limit low: $remaining requests remaining (resets at $reset_date)"
        
        if [ "$remaining" -lt "$RATE_LIMIT_ERROR_THRESHOLD" ]; then
            error "GitHub API rate limit critical: $remaining requests remaining"
            error "Consider using --cache-only or waiting until $reset_date"
            return 1
        fi
    fi
    
    return 0
}

# Get cache file path for repository
get_cache_file() {
    local repo="$1"
    echo "$CACHE_DIR/${repo}_data.json"
}

# Check if cache is valid
is_cache_valid() {
    local cache_file="$1"
    
    if [ ! -f "$cache_file" ]; then
        return 1
    fi
    
    local cache_age
    if command -v stat >/dev/null 2>&1; then
        local cache_mtime
        cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo "0")
        cache_age=$(( $(date +%s) - cache_mtime ))
    else
        # Fallback if stat is not available
        cache_age=$((CACHE_DURATION + 1))
    fi
    
    [ "$cache_age" -lt "$CACHE_DURATION" ]
}

# Get cached repository data
get_cached_data() {
    local repo="$1"
    local cache_file
    cache_file=$(get_cache_file "$repo")
    
    if [ "$CACHE_ENABLED" = "true" ] && is_cache_valid "$cache_file"; then
        cat "$cache_file" 2>/dev/null && return 0
    fi
    
    return 1
}

# Store repository data in cache
store_cache_data() {
    local repo="$1"
    local pr_data="$2"
    local issue_data="$3"
    local cache_file
    cache_file=$(get_cache_file "$repo")
    
    if [ "$CACHE_ENABLED" = "true" ]; then
        local timestamp
        timestamp=$(date +%s)
        cat > "$cache_file" <<EOF
{
  "timestamp": $timestamp,
  "pr_data": "$pr_data",
  "issue_data": "$issue_data"
}
EOF
    fi
}

# Clear cache for specific repository or all
clear_cache() {
    local repo="$1"
    
    if [ -n "$repo" ]; then
        local cache_file
        cache_file=$(get_cache_file "$repo")
        rm -f "$cache_file"
        log "Cache cleared for $repo"
    else
        rm -rf "$CACHE_DIR"
        log "All cache cleared"
    fi
}

# Display help
show_help() {
    cat << EOF
LaTeX Thesis Environment Ecosystem Manager

Prerequisites:
    - Git: Version control system
    - GitHub CLI (gh): For PR/Issue tracking (optional but recommended)
    - jq: JSON processor for parsing API responses
    - Bash: Shell interpreter (4.0+)

GitHub CLI Setup:
    gh auth login    # Authenticate with GitHub
    gh auth status   # Verify authentication

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

Cache Options:
    --no-cache      Disable cache, always fetch fresh data
    --cache-only    Use cache only, skip GitHub API calls
    --clear-cache   Clear all cached data
    --cache-status  Show cache status and location

Performance Options:
    --parallel      Enable parallel processing (default: $MAX_PARALLEL_JOBS jobs)
    --sequential    Disable parallel processing
    --quiet         Suppress progress output

Format Legend (compact mode):
    PRs: number(dr) - d=drafts, r=needs review
    Issues: number(bf!) - b=bugs, f=features, !=urgent

Examples:
    $0 status                    # Show compact status of all repos
    $0 status --long             # Show detailed status with full descriptions  
    $0 status --urgent-issues    # Show only repos with urgent issues
    $0 status --with-prs         # Show only repos with open PRs
    $0 status --needs-review     # Show only repos with PRs needing review
    $0 status --cache-only       # Fast display using cached data only
    $0 status --no-cache         # Fresh data, bypass cache
    $0 status --parallel         # Use parallel processing for speed
    $0 sync --repo latex-environment  # Sync only latex-environment
    $0 check --verbose           # Check for changes with details
    $0 claude-status             # Check CLAUDE.md git tracking
    $0 --clear-cache             # Clear all cached data
    $0 --cache-status            # Show cache information

EOF
}

# Check if repository exists
repo_exists() {
    local repo="$1"
    if [ "$repo" = "." ]; then
        [ -d "$SCRIPT_DIR/.git" ]
    else
        [ -d "$SCRIPT_DIR/$repo/.git" ]
    fi
}

# Truncate string to specified length with ellipsis (multibyte-aware)
truncate_string() {
    local str="$1"
    local max_length="$2"
    local ellipsis="..."
    
    # Get actual character count (multibyte-aware)
    local str_length
    if command -v wc >/dev/null 2>&1; then
        str_length=$(echo -n "$str" | wc -m 2>/dev/null || echo "${#str}")
    else
        str_length=${#str}
    fi
    
    if [ "$str_length" -le "$max_length" ]; then
        echo "$str"
    else
        local truncated_length=$((max_length - ${#ellipsis}))
        # Use cut for proper multibyte character handling if available
        if command -v cut >/dev/null 2>&1; then
            echo "$(echo "$str" | cut -c1-"$truncated_length" 2>/dev/null || echo "${str:0:$truncated_length}")$ellipsis"
        else
            echo "${str:0:$truncated_length}$ellipsis"
        fi
    fi
}

# Convert repository path to display name
get_repo_display_name() {
    local repo="$1"
    if [ "$repo" = "." ]; then
        echo "latex-ecosystem"
    else
        echo "$repo"
    fi
}

# Get current branch for repository
get_current_branch() {
    local repo="$1"
    if repo_exists "$repo"; then
        if [ "$repo" = "." ]; then
            (cd "$SCRIPT_DIR" && git branch --show-current 2>/dev/null || echo "detached")
        else
            (cd "$SCRIPT_DIR/$repo" && git branch --show-current 2>/dev/null || echo "detached")
        fi
    else
        echo "missing"
    fi
}

# Get repository status
get_repo_status() {
    local repo="$1"
    if repo_exists "$repo"; then
        if [ "$repo" = "." ]; then
            (cd "$SCRIPT_DIR" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        else
            (cd "$SCRIPT_DIR/$repo" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        fi
    else
        echo "missing"
    fi
}

# Get repository issue status (direct API call)
get_issue_status_direct() {
    local repo="$1"
    
    # Check GitHub CLI availability
    if ! repo_exists "$repo" || ! check_github_cli; then
        echo "0|0|0|0"
        return
    fi
    
    local target_dir
    if [ "$repo" = "." ]; then
        target_dir="$SCRIPT_DIR"
    else
        target_dir="$SCRIPT_DIR/$repo"
    fi
    
    (cd "$target_dir" && {
        # Get issues with labels for categorization using robust API call
        local issues_json
        issues_json=$(github_api_call "gh issue list --state open --json number,title,labels,createdAt")
        
        if [ "$issues_json" = "[]" ] || [ -z "$issues_json" ]; then
            echo "0|0|0|0"
            return
        fi
        
        # Count total issues using safe_jq
        local total bugs enhancements urgent
        total=$(safe_jq "$issues_json" 'length' '0')
        
        # Count by type (based on labels) using safe_jq
        bugs=$(safe_jq "$issues_json" '[.[] | select(.labels[]?.name | test("bug|error|critical|regression"; "i"))] | length' '0')
        enhancements=$(safe_jq "$issues_json" '[.[] | select(.labels[]?.name | test("enhancement|feature|improvement|request"; "i"))] | length' '0')
        urgent=$(safe_jq "$issues_json" '[.[] | select(.labels[]?.name | test("critical|urgent|high"; "i"))] | length' '0')
        
        echo "$total|$bugs|$enhancements|$urgent"
    })
}

# Get repository issue status (wrapper for compatibility)
get_issue_status() {
    local repo="$1"
    local repo_data
    repo_data=$(get_repo_data "$repo")
    echo "$repo_data" | cut -d'|' -f4-7
}

# Get repository data with cache support
get_repo_data() {
    local repo="$1"
    local force_fresh="$2"  # "true" to bypass cache
    
    # Try cache first (unless disabled or force_fresh)  
    if [ "$force_fresh" != "true" ] && [ "$CACHE_ENABLED" = "true" ]; then
        local cached_data
        if cached_data=$(get_cached_data "$repo"); then
            local pr_data issue_data
            pr_data=$(echo "$cached_data" | jq -r '.pr_data' 2>/dev/null || echo "0|0|0")
            issue_data=$(echo "$cached_data" | jq -r '.issue_data' 2>/dev/null || echo "0|0|0|0")
            echo "$pr_data|$issue_data"
            return 0
        fi
    fi
    
    # If cache-only mode and no cache available
    if [ "$CACHE_ONLY" = "true" ]; then
        echo "0|0|0|0|0|0|0"
        return 0
    fi
    
    # Check rate limit before API calls
    if ! check_rate_limit; then
        echo "0|0|0|0|0|0|0"
        return 1
    fi
    
    # Fetch fresh data
    local pr_data issue_data
    pr_data=$(get_pr_status_direct "$repo")
    issue_data=$(get_issue_status_direct "$repo")
    
    # Store in cache
    store_cache_data "$repo" "$pr_data" "$issue_data"
    
    echo "$pr_data|$issue_data"
}

# Get repository PR status (direct API call)
get_pr_status_direct() {
    local repo="$1"
    
    # Check GitHub CLI availability
    if ! repo_exists "$repo" || ! check_github_cli; then
        echo "0|0|0"
        return
    fi
    
    local target_dir
    if [ "$repo" = "." ]; then
        target_dir="$SCRIPT_DIR"
    else
        target_dir="$SCRIPT_DIR/$repo"
    fi
    
    (cd "$target_dir" && {
        # Get PR information with review status using robust API call
        local pr_json
        pr_json=$(github_api_call "gh pr list --state open --json number,title,isDraft,reviewDecision,labels")
        
        if [ "$pr_json" = "[]" ] || [ -z "$pr_json" ]; then
            echo "0|0|0"
            return
        fi
        
        # Count total PRs using safe_jq
        local total drafts needs_review
        total=$(safe_jq "$pr_json" 'length' '0')
        
        # Count draft PRs using safe_jq
        drafts=$(safe_jq "$pr_json" '[.[] | select(.isDraft == true)] | length' '0')
        
        # Count PRs needing review (not draft and no approval yet) using safe_jq
        needs_review=$(safe_jq "$pr_json" '[.[] | select(.isDraft == false and (.reviewDecision == null or .reviewDecision == "REVIEW_REQUIRED"))] | length' '0')
        
        echo "$total|$drafts|$needs_review"
    })
}

# Get repository PR status (wrapper for compatibility)
get_pr_status() {
    local repo="$1"
    local repo_data
    repo_data=$(get_repo_data "$repo")
    echo "$repo_data" | cut -d'|' -f1-3
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
            [ "$needs_review" -eq 1 ] || details="${details}s"
            details="${details} review"
        elif [ "$drafts" -gt 0 ]; then
            details="$drafts draft"
            [ "$drafts" -gt 1 ] && details="${details}s"
        elif [ "$needs_review" -gt 0 ]; then
            details="$needs_review need"
            [ "$needs_review" -eq 1 ] || details="${details}s"
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

# Show cache status
show_cache_status() {
    log "Cache Status"
    echo
    echo "Cache directory: $CACHE_DIR"
    echo "Cache duration: ${CACHE_DURATION}s ($((CACHE_DURATION / 60)) minutes)"
    echo "Cache enabled: $CACHE_ENABLED"
    echo
    
    if [ -d "$CACHE_DIR" ]; then
        local cache_files
        cache_files=$(find "$CACHE_DIR" -name "*.json" 2>/dev/null | wc -l)
        echo "Cached repositories: $cache_files"
        
        if [ "$cache_files" -gt 0 ]; then
            echo
            printf "%-30s %-20s %-10s\n" "Repository" "Cache Age" "Status"
            printf "%-30s %-20s %-10s\n" "----------" "---------" "------"
            
            for cache_file in "$CACHE_DIR"/*.json; do
                if [ -f "$cache_file" ]; then
                    local repo
                    repo=$(basename "$cache_file" _data.json)
                    local cache_age
                    if command -v stat >/dev/null 2>&1; then
                        local cache_mtime
                        cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo "0")
                        cache_age=$(( $(date +%s) - cache_mtime ))
                    else
                        cache_age="unknown"
                    fi
                    
                    local status="valid"
                    if [ "$cache_age" != "unknown" ] && [ "$cache_age" -gt "$CACHE_DURATION" ]; then
                        status="expired"
                    fi
                    
                    local age_display
                    if [ "$cache_age" = "unknown" ]; then
                        age_display="unknown"
                    else
                        age_display="${cache_age}s"
                    fi
                    
                    printf "%-30s %-20s %-10s\n" "$repo" "$age_display" "$status"
                fi
            done
        fi
    else
        echo "Cache directory does not exist"
    fi
}

# Process repositories in parallel
process_repos_parallel() {
    local repos_array=("$@")
    local pids=()
    local temp_dir
    temp_dir=$(mktemp -d)
    local job_count=0
    
    for repo in "${repos_array[@]}"; do
        # Wait if we've reached max parallel jobs
        if [ "$job_count" -ge "$MAX_PARALLEL_JOBS" ]; then
            wait "${pids[0]}"
            pids=("${pids[@]:1}")
            ((job_count--))
        fi
        
        # Start background job
        {
            local repo_data
            repo_data=$(get_repo_data "$repo" "$NO_CACHE")
            echo "$repo|$repo_data" > "$temp_dir/$repo.result"
        } &
        
        pids+=($!)
        ((job_count++))
        
        # Show progress if not quiet
        if [ "$QUIET" != "true" ]; then
            echo -n "." >&2
        fi
    done
    
    # Wait for remaining jobs
    wait
    
    if [ "$QUIET" != "true" ]; then
        echo >&2
    fi
    
    # Collect results
    for repo in "${repos_array[@]}"; do
        if [ -f "$temp_dir/$repo.result" ]; then
            cat "$temp_dir/$repo.result"
        else
            echo "$repo|0|0|0|0|0|0|0"
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
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
        # Long format: variable width, no truncation
        printf "%s\t%s\t%s\t%s\t%s\t%s\n" "Repository" "Branch" "Changes" "Last Commit" "PRs" "Issues"
        printf "%s\t%s\t%s\t%s\t%s\t%s\n" "----------" "------" "-------" "-----------" "---" "------"
    else
        # Compact format: fixed width, with truncation
        printf "%-26s %-27s %-8s %-22s %-8s %-8s\n" "Repository" "Branch" "Changes" "Last Commit" "PRs" "Issues"
        printf "%-26s %-27s %-8s %-22s %-8s %-8s\n" "----------" "------" "-------" "-----------" "---" "------"
    fi
    
    for repo in "${REPOS[@]}"; do
        if [ -n "$specific_repo" ] && [ "$specific_repo" != "$repo" ]; then
            continue
        fi
        
        if repo_exists "$repo"; then
            branch=$(get_current_branch "$repo")
            changes=$(get_repo_status "$repo")
            if [ "$repo" = "." ]; then
                last_commit=$(cd "$SCRIPT_DIR" && git log -1 --format="%h %cr" 2>/dev/null || echo "unknown")
            else
                last_commit=$(cd "$SCRIPT_DIR/$repo" && git log -1 --format="%h %cr" 2>/dev/null || echo "unknown")
            fi
            issue_data=$(get_issue_status "$repo")
            issue_info=$(format_issue_info "$issue_data" "$LONG_FORMAT")
            pr_data=$(get_pr_status "$repo")
            pr_info=$(format_pr_info "$pr_data" "$LONG_FORMAT")
            
            # Convert repository name and truncate for display
            local repo_name
            repo_name=$(get_repo_display_name "$repo")
            
            if [ "$LONG_FORMAT" = "true" ]; then
                # Long format: no truncation, show full names
                repo_display="$repo_name"
                branch_display="$branch"
            else
                # Compact format: truncate for fixed-width table
                repo_display=$(truncate_string "$repo_name" $REPO_COLUMN_WIDTH)
                branch_display=$(truncate_string "$branch" $BRANCH_COLUMN_WIDTH)
            fi
            
            # Extract counts for filtering
            IFS='|' read -r _ bugs enhancements urgent <<< "$issue_data"
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
                # Long format: tab-separated, variable width
                if [ "$changes" -gt 0 ]; then
                    if [ "$urgent" -gt 0 ]; then
                        printf "%s\t%s\t${YELLOW}%s${NC}\t%s\t%s\t${RED}%s${NC}\n" "$repo_display" "$branch_display" "$changes" "$last_commit" "$pr_info" "$issue_info"
                    else
                        printf "%s\t%s\t${YELLOW}%s${NC}\t%s\t%s\t%s\n" "$repo_display" "$branch_display" "$changes" "$last_commit" "$pr_info" "$issue_info"
                    fi
                else
                    if [ "$urgent" -gt 0 ]; then
                        printf "%s\t%s\t${GREEN}%s${NC}\t%s\t%s\t${RED}%s${NC}\n" "$repo_display" "$branch_display" "clean" "$last_commit" "$pr_info" "$issue_info"
                    else
                        printf "%s\t%s\t${GREEN}%s${NC}\t%s\t%s\t%s\n" "$repo_display" "$branch_display" "clean" "$last_commit" "$pr_info" "$issue_info"
                    fi
                fi
            else
                # Short format with fixed width columns
                if [ "$changes" -gt 0 ]; then
                    if [ "$urgent" -gt 0 ]; then
                        printf "%-26s %-27s ${YELLOW}%-8s${NC} %-22s %-8s ${RED}%-8s${NC}\n" "$repo_display" "$branch_display" "$changes" "$last_commit" "$pr_info" "$issue_info"
                    else
                        printf "%-26s %-27s ${YELLOW}%-8s${NC} %-22s %-8s %-8s\n" "$repo_display" "$branch_display" "$changes" "$last_commit" "$pr_info" "$issue_info"
                    fi
                else
                    if [ "$urgent" -gt 0 ]; then
                        printf "%-26s %-27s ${GREEN}%-8s${NC} %-22s %-8s ${RED}%-8s${NC}\n" "$repo_display" "$branch_display" "clean" "$last_commit" "$pr_info" "$issue_info"
                    else
                        printf "%-26s %-27s ${GREEN}%-8s${NC} %-22s %-8s %-8s\n" "$repo_display" "$branch_display" "clean" "$last_commit" "$pr_info" "$issue_info"
                    fi
                fi
            fi
            
            if [ "$verbose" = "true" ]; then
                if [ "$repo" = "." ]; then
                    (cd "$SCRIPT_DIR" && git status --short 2>/dev/null | sed 's/^/    /')
                else
                    (cd "$SCRIPT_DIR/$repo" && git status --short 2>/dev/null | sed 's/^/    /')
                fi
            fi
        else
            # Handle missing repos display
            local repo_name
            repo_name=$(get_repo_display_name "$repo")
            
            if [ "$LONG_FORMAT" = "true" ]; then
                repo_display="$repo_name"
            else
                repo_display=$(truncate_string "$repo_name" $REPO_COLUMN_WIDTH)
            fi
            
            if [ "$LONG_FORMAT" = "true" ]; then
                printf "%s\t${RED}%s${NC}\t%s\t%s\t%s\t%s\n" "$repo_display" "missing" "-" "-" "-" "-"
            else
                printf "%-26s ${RED}%-27s${NC} %-8s %-22s %-8s %-8s\n" "$repo_display" "missing" "-" "-" "-" "-"
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

# Performance and cache options
CACHE_ENABLED="$DEFAULT_CACHE_ENABLED"
NO_CACHE=false
CACHE_ONLY=false
# PARALLEL_ENABLED=true  # TODO: Implement parallel processing
QUIET=false

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
        --no-cache)
            CACHE_ENABLED=false
            NO_CACHE=true
            shift
            ;;
        --cache-only)
            CACHE_ONLY=true
            shift
            ;;
        --clear-cache)
            COMMAND="clear-cache"
            shift
            ;;
        --cache-status)
            COMMAND="cache-status"
            shift
            ;;
        --parallel)
            # TODO: Implement parallel processing
            shift
            ;;
        --sequential)
            # TODO: Implement sequential processing
            shift
            ;;
        --quiet)
            QUIET=true
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
init_cache

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
    clear-cache)
        clear_cache "$SPECIFIC_REPO"
        ;;
    cache-status)
        show_cache_status
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
