#!/bin/bash
# LaTeX Ecosystem Setup Script
# This script sets up the complete LaTeX ecosystem development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ECOSYSTEM_REPO="https://github.com/smkwlab/latex-ecosystem"
GITHUB_ORG="smkwlab"

# Repository lists
CORE_REPOS=(
    "texlive-ja-textlint"
    "latex-environment"
    "latex-release-action"
)

TEMPLATE_REPOS=(
    "sotsuron-template"
    "wr-template"
    "latex-template"
    "sotsuron-report-template"
)

TOOL_REPOS=(
    "thesis-management-tools"
    "ai-academic-paper-reviewer"
    "aldc"
)

# Functions
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check git
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed"
        exit 1
    fi
    print_status "Git is installed"
    
    # Check gh (optional)
    if command -v gh &> /dev/null; then
        print_status "GitHub CLI is installed"
    else
        print_warning "GitHub CLI is not installed (optional)"
    fi
    
    # Check Docker (optional)
    if command -v docker &> /dev/null; then
        print_status "Docker is installed"
    else
        print_warning "Docker is not installed (optional for testing)"
    fi
}

setup_base_directory() {
    echo -e "\nSetting up base directory..."
    
    # Use environment variable or current directory
    BASE_DIR="${LATEX_ECOSYSTEM_BASE:-$(pwd)/latex-ecosystem-dev}"
    
    if [ -d "$BASE_DIR" ]; then
        print_warning "Directory $BASE_DIR already exists"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        mkdir -p "$BASE_DIR"
        print_status "Created directory: $BASE_DIR"
    fi
    
    cd "$BASE_DIR"
}

setup_ecosystem_management() {
    echo -e "\nSetting up ecosystem management..."
    
    # Clone latex-ecosystem repository
    if [ ! -d .git ]; then
        # Try gh first, then git clone
        if command -v gh &> /dev/null; then
            if gh repo clone "${GITHUB_ORG}/latex-ecosystem" . -- --depth 1; then
                print_status "Cloned latex-ecosystem repository using gh"
            else
                print_error "Failed to clone with gh, trying git..."
                git clone --depth 1 "${ECOSYSTEM_REPO}.git" .
                print_status "Cloned latex-ecosystem repository using git"
            fi
        else
            git clone --depth 1 "${ECOSYSTEM_REPO}.git" .
            print_status "Cloned latex-ecosystem repository using git"
        fi
    else
        print_warning "Directory already contains a git repository"
    fi
    
    # Verify ecosystem-manager.sh exists
    if [ -f ecosystem-manager.sh ]; then
        print_status "ecosystem-manager.sh is ready"
    else
        print_error "ecosystem-manager.sh not found"
        exit 1
    fi
}

clone_repositories() {
    local repos=("$@")
    for repo in "${repos[@]}"; do
        if [ -d "$repo" ]; then
            print_warning "Repository $repo already exists, skipping"
        else
            echo "Cloning $repo..."
            # Try gh first if available
            if command -v gh &> /dev/null; then
                if gh repo clone "${GITHUB_ORG}/${repo}" 2>/dev/null; then
                    print_status "Cloned $repo using gh"
                else
                    # Fallback to git clone
                    if git clone "git@github.com:${GITHUB_ORG}/${repo}.git" 2>/dev/null; then
                        print_status "Cloned $repo (SSH)"
                    elif git clone "https://github.com/${GITHUB_ORG}/${repo}.git"; then
                        print_status "Cloned $repo (HTTPS)"
                    else
                        print_error "Failed to clone $repo"
                    fi
                fi
            else
                # No gh available, use git directly
                if git clone "git@github.com:${GITHUB_ORG}/${repo}.git" 2>/dev/null; then
                    print_status "Cloned $repo (SSH)"
                elif git clone "https://github.com/${GITHUB_ORG}/${repo}.git"; then
                    print_status "Cloned $repo (HTTPS)"
                else
                    print_error "Failed to clone $repo"
                fi
            fi
        fi
    done
}

main() {
    echo "LaTeX Ecosystem Setup Script"
    echo "============================"
    
    # Parse arguments
    CLONE_ONLY=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --only)
                CLONE_ONLY="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --only <type>  Clone only specific type (core|templates|tools)"
                echo "  --help         Show this help"
                echo ""
                echo "Examples:"
                echo "  $0               # Setup all repositories"
                echo "  $0 --only core   # Clone only core infrastructure repos"
                echo "  $0 --only tools  # Clone only tool repos"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Run setup steps
    check_prerequisites
    setup_base_directory
    setup_ecosystem_management
    
    # Clone repositories based on options
    echo -e "\nCloning repositories..."
    
    if [ -z "$CLONE_ONLY" ] || [ "$CLONE_ONLY" = "core" ]; then
        echo -e "\nCloning core infrastructure repositories..."
        clone_repositories "${CORE_REPOS[@]}"
    fi
    
    if [ -z "$CLONE_ONLY" ] || [ "$CLONE_ONLY" = "templates" ]; then
        echo -e "\nCloning template repositories..."
        clone_repositories "${TEMPLATE_REPOS[@]}"
    fi
    
    if [ -z "$CLONE_ONLY" ] || [ "$CLONE_ONLY" = "tools" ]; then
        echo -e "\nCloning tool repositories..."
        clone_repositories "${TOOL_REPOS[@]}"
    fi
    
    # Final verification
    echo -e "\nVerifying setup..."
    if [ -x ecosystem-manager.sh ]; then
        ./ecosystem-manager.sh status
        print_status "Setup completed successfully!"
        echo -e "\nNext steps:"
        echo "  cd $BASE_DIR"
        echo "  ./ecosystem-manager.sh check"
    else
        print_error "Setup verification failed"
        exit 1
    fi
}

# Run main function
main "$@"