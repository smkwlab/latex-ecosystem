# LaTeX Ecosystem Setup and Management Guide

This comprehensive guide covers setup, dependency management, and release processes for the LaTeX ecosystem at Kyushu Sangyo University.

## Prerequisites

### Required Tools
- **Git**: Version control system
- **GitHub CLI (`gh`)**: Required for PR/Issue tracking, recommended for easier cloning
- **jq**: JSON processor (required for ecosystem-manager.sh)
- **Bash**: Shell interpreter (version 4.0+)

### Optional Tools
- **Docker**: For testing Docker images
- **VSCode**: Recommended IDE for development

### GitHub CLI Setup

```bash
# Install GitHub CLI
# macOS
brew install gh

# Ubuntu/Debian  
sudo apt install gh

# Windows (with Scoop)
scoop install gh

# Authenticate
gh auth login

# Verify authentication
gh auth status
```

**Note**: Full ecosystem management features require GitHub CLI authentication. Without it, PR/Issue tracking will not work.

## Quick Setup

```bash
# One-line ecosystem setup
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/latex-ecosystem/main/setup.sh)"
```

## Manual Setup

### 1. Clone Management Repository

```bash
# Create development directory
mkdir latex-ecosystem-dev
cd latex-ecosystem-dev

# Clone management repository
gh repo clone smkwlab/latex-ecosystem .

# Or with git
git clone https://github.com/smkwlab/latex-ecosystem.git .
```

### 2. Run Setup Script

```bash
# Execute setup script
./setup.sh

# This will clone all component repositories:
# - texlive-ja-textlint
# - latex-environment
# - sotsuron-template
# - thesis-management-tools
# - latex-release-action
# - ai-academic-paper-reviewer
# - aldc
# - wr-template
# - latex-template
# - ise-report-template
```

### 3. Verify Installation

```bash
# Check ecosystem status
./ecosystem-manager.sh status

# Verify all repositories are present
./ecosystem-manager.sh deps
```

## Dependency Management

### Ecosystem Dependency Structure

```
texlive-ja-textlint (Docker base)
    ↓
latex-environment (DevContainer template)
    ↓
├── sotsuron-template (LaTeX thesis)
├── ise-report-template (HTML reports with textlint)
├── wr-template (Weekly reports)
├── latex-template (Basic LaTeX)
└── sotsuron-report-template (Thesis reports)

Supporting Infrastructure:
├── latex-release-action → (Used by templates)
├── ai-academic-paper-reviewer → (Used by thesis repos)  
├── aldc → latex-environment (release branch)
└── thesis-management-tools → (Management workflows)
```

### Standard Update Process

#### Phase 1: Base Image Update (texlive-ja-textlint)

```bash
cd texlive-ja-textlint/

# Create feature branch
git checkout -b feature/update-2025d

# Make changes (package updates, security patches, etc.)
# Edit alpine/package.json, debian/package.json, etc.

# Test locally
docker build -f alpine/Dockerfile -t test-alpine .
docker build -f debian/Dockerfile -t test-debian .

# Commit and push
git add .
git commit -m "Update to TeXLive 2025d with security patches"
git push origin feature/update-2025d

# Create PR
gh pr create --title "Update to TeXLive 2025d" --body "- Security updates
- Package compatibility fixes
- Multi-architecture support verified"

# After PR approval and merge
git checkout main && git pull origin main
git tag 2025d -m "TeXLive 2025d release"
git push origin 2025d
```

#### Phase 2: Environment Update (latex-environment)

```bash
cd ../latex-environment/

# Wait for texlive-ja-textlint Docker image to be built
# Check registry: ghcr.io/smkwlab/texlive-ja-textlint:2025d

# Create feature branch
git checkout -b feature/update-texlive-2025d

# Update devcontainer to use new image
vim .devcontainer/devcontainer.json
# Change: "image": "ghcr.io/smkwlab/texlive-ja-textlint:2025d"

# Test the update
# - Start devcontainer in VS Code
# - Compile sample documents
# - Verify textlint functionality

# Commit and create PR
git add .devcontainer/devcontainer.json
git commit -m "Update to texlive-ja-textlint 2025d"
git push origin feature/update-texlive-2025d
gh pr create --title "Update to texlive-ja-textlint 2025d" --body "- Update base Docker image
- Compatibility verified with sample documents"
```

#### Phase 3: Template Updates

```bash
# Update each template repository
for template in sotsuron-template wr-template latex-template ise-report-template; do
    echo "Updating $template..."
    cd ../$template/
    
    # Templates inherit from latex-environment, so usually no direct changes needed
    # But verify compatibility and update if necessary
    
    # Test compilation
    if [ -f "main.tex" ] || [ -f "sotsuron.tex" ]; then
        # Open in VS Code with devcontainer to test
        echo "Manual testing required for $template"
    fi
done
```

## Release Management

### Release Types

1. **Regular Updates** (Monthly/Bi-monthly)
   - Feature additions, dependency updates
   - Non-breaking improvements
   - Example: 2025a → 2025b

2. **Security Updates** (As needed)
   - Critical security patches
   - Example: 2025b → 2025b-security

3. **Major Updates** (Annually)
   - TeXLive major version updates
   - Architecture changes
   - Example: 2024c → 2025

### Release Workflow

#### 1. Planning Phase

```bash
# Create release planning issue in primary repository
gh issue create --title "Release Planning: texlive-ja-textlint 2025d" --body "
## Release Goals
- [ ] Security updates for base Alpine/Debian images
- [ ] Node.js 18 → 20 migration
- [ ] New textlint rules for academic writing

## Timeline
- Development: Week 1-2
- Testing: Week 3
- Release: Week 4

## Breaking Changes
- Node.js version requirement change
- Migration guide needed

## Testing Requirements
- [ ] Multi-architecture builds (AMD64, ARM64)
- [ ] Integration tests with latex-environment
- [ ] Template compilation verification
"
```

#### 2. Development Phase

```bash
# Follow Phase 1-3 dependency update process
# Ensure all changes are properly tested
# Create comprehensive PRs with testing evidence
```

#### 3. Testing Phase

```bash
# Ecosystem-wide compatibility testing
./ecosystem-manager.sh check

# Test critical workflows
cd thesis-management-tools/
./thesis-repo-manager.sh --test-mode

# Student workflow verification
cd test-repos/
# Verify repository creation and compilation
```

#### 4. Release Phase

```bash
# Tag releases in dependency order
cd texlive-ja-textlint/
git tag 2025d && git push origin 2025d

cd ../latex-environment/
git tag 2025.1 && git push origin 2025.1

# Update ecosystem tracking
cd ../
vim ECOSYSTEM.md  # Update compatibility matrix
git add ECOSYSTEM.md
git commit -m "Update compatibility matrix for 2025d release"
```

#### 5. Communication Phase

```bash
# Create release announcements
gh release create 2025d --title "TeXLive 2025d Release" --notes "
## New Features
- Updated TeXLive packages
- Enhanced security
- Improved multi-architecture support

## Breaking Changes
- Node.js 18 → 20 (update your local development)

## Migration Guide
See docs/CLAUDE-SETUP.md for update instructions
"

# Notify stakeholders
# - Update lab documentation
# - Inform students of any required actions
# - Update course materials if needed
```

## Emergency Procedures

### Critical Security Updates

```bash
# Emergency workflow for security patches
# 1. Assess vulnerability impact
# 2. Create hotfix branch
git checkout -b hotfix/security-CVE-2025-XXXX

# 3. Apply minimal fixes
# 4. Expedited testing
# 5. Emergency release with clear communication
git tag 2025b-security1
gh release create 2025b-security1 --title "Security Hotfix" --notes "
⚠️ SECURITY UPDATE

Addresses CVE-2025-XXXX in base image.
All users should update immediately.
"
```

### Rollback Procedures

```bash
# If a release causes issues
# 1. Identify problematic version
# 2. Revert to previous stable tag

cd texlive-ja-textlint/
git checkout 2025c  # Previous stable version
git tag 2025d-rollback
git push origin 2025d-rollback

# 3. Update latex-environment to use rollback version
cd ../latex-environment/
# Update devcontainer.json to use 2025c or 2025d-rollback

# 4. Communicate rollback to users
gh issue create --title "ROLLBACK: 2025d → 2025c" --body "
Issue identified in 2025d release.
Temporarily rolling back to 2025c.
Investigation ongoing.
"
```

## Ecosystem Maintenance

### Regular Maintenance Tasks

```bash
# Weekly maintenance
./ecosystem-manager.sh status
./ecosystem-manager.sh claude-status

# Monthly maintenance
./ecosystem-manager.sh sync
# Review and update documentation
# Check for upstream updates (TeXLive, Node.js, etc.)

# Quarterly maintenance
# Security audit
# Performance review
# Student feedback integration
```

### Monitoring and Alerts

```bash
# Set up monitoring for:
# - Docker image build failures
# - GitHub Actions failures
# - Student repository creation issues
# - Compilation failures in templates

# Use ecosystem-manager.sh for automated checks
./ecosystem-manager.sh check --automated
```

## Development Best Practices

### Branch Strategy
- Always use feature branches
- Never commit directly to main
- Use descriptive branch names: `feature/`, `fix/`, `hotfix/`

### Testing Requirements
- All changes must pass automated tests
- Manual testing for template changes
- Cross-platform compatibility verification

### Documentation
- Update CHANGELOG.md for user-facing changes
- Maintain compatibility matrices
- Provide migration guides for breaking changes

## Troubleshooting

### Common Issues

**Setup Script Failures**:
```bash
# Check GitHub CLI authentication
gh auth status

# Verify repository access
gh repo view smkwlab/latex-ecosystem

# Manual clone if automated setup fails
git clone https://github.com/smkwlab/texlive-ja-textlint.git
```

**Dependency Update Issues**:
```bash
# Check Docker image availability
docker pull ghcr.io/smkwlab/texlive-ja-textlint:2025d

# Verify image compatibility
docker run --rm ghcr.io/smkwlab/texlive-ja-textlint:2025d tlmgr --version
```

**Release Process Issues**:
```bash
# Check GitHub Actions status
gh run list --repo smkwlab/texlive-ja-textlint

# Verify tag creation
git tag -l | grep 2025

# Check registry uploads
# Visit: https://github.com/orgs/smkwlab/packages
```

For additional troubleshooting, see individual repository documentation and [CLAUDE-WORKFLOWS.md](CLAUDE-WORKFLOWS.md).