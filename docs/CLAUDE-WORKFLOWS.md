# Ecosystem Management Workflows

This document provides workflow examples specifically for ecosystem management tasks using the LaTeX ecosystem management repository.

## Ecosystem Management Commands

### Comprehensive Command Reference
```bash
# Show status of all repositories
./ecosystem-manager.sh status

# Check dependency relationships
./ecosystem-manager.sh deps

# Sync all repositories
./ecosystem-manager.sh sync

# Check for uncommitted changes
./ecosystem-manager.sh check

# Show version information
./ecosystem-manager.sh versions

# Check CLAUDE.md tracking status
./ecosystem-manager.sh claude-status
```

### Status Monitoring Examples
```bash
# Quick ecosystem health check
./ecosystem-manager.sh status | grep -E "(AHEAD|BEHIND|DIRTY)"

# Version compatibility check
./ecosystem-manager.sh versions | grep -E "texlive-ja-textlint|latex-environment"

# Documentation consistency check
./ecosystem-manager.sh claude-status
```

## Repository Navigation and Operations

### Shell Command Gotchas

#### Directory Navigation
```bash
# Working in ecosystem management
pwd  # /path/to/latex-ecosystem (management repo)
git status  # Shows management repository status

# Working in component
cd latex-environment/
pwd  # /path/to/latex-ecosystem/latex-environment (different repo)
git status  # Shows latex-environment repository status

# Return to management repository
cd ..
git status  # Shows management repository status again
```

#### Git Operations
```bash
# Management repository operations
git add ECOSYSTEM.md docs/
git commit -m "Update ecosystem documentation"

# Component repository operations  
cd latex-environment/
git add .devcontainer/devcontainer.json
git commit -m "Update devcontainer config"
git push origin feature-branch

# Return to management repository
cd ..
git status  # Completely separate Git history
```

## Workflow Guidelines

### For Ecosystem-level Changes

#### Documentation Updates
```bash
# Update ecosystem documentation
vim ECOSYSTEM.md  # Edit ecosystem overview
vim docs/CLAUDE-ARCHITECTURE.md  # Edit architecture details

# Commit ecosystem changes
git add ECOSYSTEM.md docs/
git commit -m "Update ecosystem architecture documentation"
git push origin main
```

#### Cross-repository Coordination
```bash
# Check current state
./ecosystem-manager.sh status
./ecosystem-manager.sh versions

# Coordinate updates
vim ECOSYSTEM.md  # Document planned changes

# Create issues in affected repositories
cd latex-environment/
gh issue create --title "Update for texlive-ja-textlint v2025c"

cd ../sotsuron-template/
gh issue create --title "Align with updated latex-environment"
```

### For Component-specific Changes

#### Working in Components
```bash
# Navigate to specific repository
cd latex-environment/

# Create feature branch
git checkout -b feature/update-textlint-config

# Make changes
vim .textlintrc
git add .textlintrc
git commit -m "Update textlint configuration"

# Push and create PR
git push origin feature/update-textlint-config
gh pr create --title "Update textlint configuration"

# Return to ecosystem management
cd ..
```

#### Tracking Component Changes
```bash
# Monitor component repository changes
cd latex-environment/
git log --oneline -10

# Check if changes affect other components
cd ../sotsuron-template/
# Test with updated latex-environment

# Update compatibility documentation
cd ..
vim ECOSYSTEM.md  # Update compatibility matrix
```

## Cross-repository Issue Management

### Coordinated Issue Creation
```bash
# For ecosystem-wide changes affecting multiple repositories
echo "Creating coordinated issues for texlive update..."

# Document in ecosystem management
vim ECOSYSTEM.md  # Add to Known Issues or Planned Updates

# Create issues in affected repositories
repositories=("texlive-ja-textlint" "latex-environment" "sotsuron-template")
for repo in "${repositories[@]}"; do
    cd "$repo/"
    gh issue create --title "Update for TeXLive 2025c" --body "See latex-ecosystem issue #XX"
    cd ..
done
```

### Issue Tracking and Coordination
```bash
# Track progress across repositories
./ecosystem-manager.sh status
./ecosystem-manager.sh versions

# Check issue status across ecosystem
for repo in */; do
    if [ -d "$repo/.git" ]; then
        echo "=== $repo ==="
        cd "$repo"
        gh issue list --label "ecosystem-update"
        cd ..
    fi
done
```

## Testing and Validation

### Ecosystem-wide Testing
```bash
# Validate all repositories
./ecosystem-manager.sh check

# Test compilation across templates
templates=("sotsuron-template" "wr-template" "latex-template")
for template in "${templates[@]}"; do
    echo "Testing $template..."
    cd "$template/"
    if [ -f "test.tex" ]; then
        latexmk -pdf test.tex
    fi
    cd ..
done
```

### Compatibility Validation
```bash
# Check version compatibility
./ecosystem-manager.sh versions > versions.txt

# Validate dependency chain
echo "Checking texlive-ja-textlint → latex-environment compatibility..."
cd latex-environment/
grep -r "texlive-ja-textlint" .devcontainer/

# Check template compatibility
cd ../sotsuron-template/
grep -r "latex-environment" .devcontainer/
```

## Ecosystem Coordination Tasks

### Cross-Repository Documentation Updates
```bash
# When CLAUDE.md structure changes across ecosystem
./ecosystem-manager.sh claude-status  # Check current state

# Plan documentation updates
for repo in texlive-ja-textlint latex-environment sotsuron-template; do
    cd $repo/
    echo "Planning docs update for $repo"
    # Create feature branch, update docs/, create PR
    cd ..
done

# Track progress
./ecosystem-manager.sh claude-status  # Verify updates
```

### Issue Coordination
```bash
# Create coordinated issues for ecosystem-wide changes
echo "Creating coordinated issues for major update..."

# Document in ecosystem management
vim ECOSYSTEM.md  # Add to Known Issues or Planned Updates

# Create issues in affected repositories  
repositories=("texlive-ja-textlint" "latex-environment" "sotsuron-template")
for repo in "${repositories[@]}"; do
    cd "$repo/"
    gh issue create --title "Update for ecosystem change XYZ" --body "See latex-ecosystem management repository for coordination"
    cd ..
done
```

## Best Practices

### Repository Boundary Management
- Always check `pwd` before git operations
- Use `git status` to confirm which repository you're working in
- Keep ecosystem documentation in management repository's docs/
- Keep component documentation in component repository's docs/

### Documentation Management
- **Management docs/**: Ecosystem-wide architecture, coordination workflows
- **Component docs/**: Component-specific development, usage, troubleshooting
- **Cross-reference**: Link between management and component documentation where appropriate

### Communication Patterns
- Use ecosystem management repository for architectural decisions
- Create coordinated issues for cross-repository changes
- Document compatibility matrices and update procedures
- Maintain clear separation between ecosystem and component concerns