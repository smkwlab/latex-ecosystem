# Ecosystem Management Workflows

This document provides workflow examples specifically for ecosystem management tasks using the LaTeX ecosystem management repository.

## Ecosystem Management Commands

### Comprehensive Command Reference

The manager is an Elixir escript. Build it once with
`(cd ecosystem_manager && mix escript.build)`, then:

```bash
# Show status of all repositories (default command)
./ecosystem_manager/ecosystem-manager status

# Detailed status: branch, uncommitted changes, last commit, PRs, issues
./ecosystem_manager/ecosystem-manager status --long

# Fast status without GitHub API calls
./ecosystem_manager/ecosystem-manager status --fast

# Filter: urgent issues / open PRs / PRs needing review
./ecosystem_manager/ecosystem-manager status --urgent-issues
./ecosystem_manager/ecosystem-manager status --with-prs
./ecosystem_manager/ecosystem-manager status --needs-review

# Status across every configured workspace, or a specific one by name
./ecosystem_manager/ecosystem-manager status --all
./ecosystem_manager/ecosystem-manager status -w dns   # or --workspace NAME

# Tune parallelism (default: 8)
./ecosystem_manager/ecosystem-manager status --max-concurrency 4

# Show repository configuration and sources
./ecosystem_manager/ecosystem-manager repos

# Auto-discover ecosystem repositories, record them in the user config,
# and register the workspace
./ecosystem_manager/ecosystem-manager repos --sync

# Show the resolved workspace path / list all configured workspaces
./ecosystem_manager/ecosystem-manager workspace
./ecosystem_manager/ecosystem-manager workspace --list

# Create example user configuration files
./ecosystem_manager/ecosystem-manager init-config

# Show current configuration
./ecosystem_manager/ecosystem-manager config
```

### Status Monitoring Examples
```bash
# Quick ecosystem health check (rows with branch/commit/change info)
./ecosystem_manager/ecosystem-manager status --long

# Show only repositories that need attention
./ecosystem_manager/ecosystem-manager status --urgent-issues
./ecosystem_manager/ecosystem-manager status --needs-review

# Version compatibility is tracked in ECOSYSTEM.md (compatibility matrix)
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
./ecosystem_manager/ecosystem-manager status

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
./ecosystem_manager/ecosystem-manager status --with-prs

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
# Validate all repositories (branches, uncommitted changes)
./ecosystem_manager/ecosystem-manager status --long

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
# Version compatibility is documented in ECOSYSTEM.md (compatibility matrix);
# review it when coordinating updates.

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
./ecosystem_manager/ecosystem-manager status  # Check current state

# Plan documentation updates
for repo in texlive-ja-textlint latex-environment sotsuron-template; do
    cd $repo/
    echo "Planning docs update for $repo"
    # Create feature branch, update docs/, create PR
    cd ..
done

# Track progress
./ecosystem_manager/ecosystem-manager status  # Verify updates
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

## Student Repository Workflows

### Student Repository Creation
```bash
# Create student thesis repository (automated)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/student-repo-management/main/create-repo/setup.sh)" bash thesis

# Create weekly report repository
STUDENT_ID=k21rs001 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/student-repo-management/main/create-repo/setup.sh)" bash wr

# The final argument selects the document type. setup.sh supports five types:
# thesis, wr, latex, ise, poster.
```

### Student Progress Monitoring
```bash
# Monitor all students' thesis progress
./thesis-monitor/thesis-monitor status

# Show only protection status
./thesis-monitor/thesis-monitor status --show-protection

# Verbose output
./thesis-monitor/thesis-monitor status --verbose
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

## Related Documentation

- [CLAUDE-ARCHITECTURE.md](CLAUDE-ARCHITECTURE.md) - Ecosystem structure, dependencies, repository boundaries
- [CLAUDE-SETUP.md](CLAUDE-SETUP.md) - Environment setup for ecosystem management
- [PR-REVIEW-GUIDELINES.md](PR-REVIEW-GUIDELINES.md) - Pull Request review guidelines