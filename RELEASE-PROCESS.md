# Release Process Guide

This document outlines the release process for the LaTeX thesis environment ecosystem.

## Release Types

### 1. Regular Updates
- **Frequency**: Monthly or bi-monthly
- **Purpose**: Feature additions, dependency updates, non-breaking improvements
- **Example**: texlive-ja-textlint 2025a → 2025b

### 2. Security Updates
- **Frequency**: As needed
- **Purpose**: Security patches, critical bug fixes
- **Example**: texlive-ja-textlint 2025b → 2025b-security

### 3. Major Updates
- **Frequency**: Annually or when TeXLive releases
- **Purpose**: Major version bumps, significant architecture changes
- **Example**: texlive-ja-textlint 2024c → 2025

### 4. Breaking Changes
- **Frequency**: Rarely, only when necessary
- **Purpose**: User-facing API changes, deprecated feature removal
- **Example**: Node.js user → texuser migration (2025d)

## Release Workflow

### Pre-Release Phase

#### 1. Planning and Preparation
```bash
# 1. Create release planning issue
# Title: "Release Planning: [Component] [Version]"
# Include:
# - Feature list
# - Breaking changes
# - Timeline
# - Testing requirements

# 2. Update version tracking
# Update VERSIONS.md with planned releases
# Check compatibility matrix

# 3. Prepare documentation
# Update CHANGELOG.md
# Prepare migration guides if needed
```

#### 2. Development and Testing
```bash
# 1. Feature development in feature branches
git checkout -b feature/description
# Development work
git commit -m "feat: description"

# 2. Create PR for review
# Include detailed description
# Reference planning issue
# Add appropriate labels

# 3. Automated testing
# GitHub Actions run full test suite
# Manual testing for complex changes
```

### Release Execution

#### Step 1: Base Component Release (texlive-ja-textlint)

1. **Final preparations**
   ```bash
   cd texlive-ja-textlint/
   git checkout main
   git pull origin main
   
   # Verify all PRs are merged
   # Check GitHub Actions status
   # Review final changes
   ```

2. **Create and push tag**
   ```bash
   # For regular release
   git tag 2025d -m "Release 2025d: Add texuser support
   
   - Add dedicated texuser (UID:2000, GID:2000)
   - Improve security with non-root execution
   - Maintain compatibility with existing environments
   
   See CHANGELOG.md for detailed changes."
   
   git push origin 2025d
   ```

3. **Monitor automated build**
   ```bash
   # Watch GitHub Actions progress
   # Verify builds complete successfully:
   # - build-alpine (AMD64)
   # - build-debian (AMD64)
   # - build-debian-arm64 (ARM64)
   # - create-manifests (multi-arch)
   ```

4. **Verify published images**
   ```bash
   # Test image availability
   docker pull ghcr.io/smkwlab/texlive-ja-textlint:2025d
   
   # Basic functionality test
   docker run --rm ghcr.io/smkwlab/texlive-ja-textlint:2025d whoami
   # Expected: texuser
   
   docker run --rm ghcr.io/smkwlab/texlive-ja-textlint:2025d latexmk --version
   # Expected: Version info
   ```

#### Step 2: Template Environment Release (latex-environment)

1. **Wait for dependency availability**
   ```bash
   # Ensure Docker image is fully available
   # Check GitHub Container Registry
   # Test pull from different locations
   ```

2. **Update and test**
   ```bash
   cd latex-environment/
   git checkout -b update-texlive-2025d
   
   # Update .devcontainer/devcontainer.json
   # - image: ghcr.io/smkwlab/texlive-ja-textlint:2025d
   # - remoteUser: texuser (if applicable)
   # - version comment
   
   # Local testing
   code .  # Open in VS Code
   # Test DevContainer rebuild
   # Verify LaTeX compilation
   # Test all extensions work
   ```

3. **Create PR and release**
   ```bash
   git add .devcontainer/devcontainer.json
   git commit -m "Update texlive-ja-textlint to 2025d
   
   - Update base image to 2025d
   - Switch to texuser for improved security
   - Maintain full compatibility with existing workflows"
   
   git push origin update-texlive-2025d
   # Create PR, review, merge
   
   # After merge:
   git checkout main
   git pull origin main
   git tag v0.5.1 -m "Release v0.5.1: texlive-ja-textlint 2025d support"
   git push origin v0.5.1
   ```

#### Step 3: Template Repository Updates

1. **Prioritize critical templates**
   ```bash
   # Priority order:
   # 1. sotsuron-template (most used)
   # 2. latex-template (basic template)
   # 3. wr-template (regular use)
   # 4. sotsuron-report-template
   # 5. ise-report-template (HTML-focused)
   ```

2. **Update each template**
   ```bash
   cd sotsuron-template/
   git checkout -b update-latex-environment-v0.5.1
   
   # Update devcontainer references if any
   # Update documentation
   # Test template functionality
   
   git commit -m "Update latex-environment to v0.5.1"
   git push origin update-latex-environment-v0.5.1
   # Create PR, review, merge, tag
   ```

### Post-Release Phase

#### 1. Verification and Monitoring

```bash
# 1. End-to-end testing
# Create new repository using updated templates
# Test full workflow: create → develop → build → release

# 2. Monitor for issues
# Watch GitHub Issues across all repositories
# Monitor user feedback
# Check error rates in GitHub Actions

# 3. Documentation verification
# Verify all documentation is up-to-date
# Test migration guides with real scenarios
# Update ecosystem status
```

#### 2. Communication

1. **Release announcements**
   ```markdown
   # Create GitHub Release with notes
   Title: "texlive-ja-textlint 2025d: Enhanced Security with texuser"
   
   ## What's New
   - Dedicated texuser (UID:2000) for improved security
   - Enhanced Docker image stability
   - Maintained compatibility with existing workflows
   
   ## Breaking Changes
   - New environments will use texuser by default
   - Existing environments continue to work unchanged
   
   ## Migration Guide
   [Link to migration documentation]
   
   ## Technical Details
   [Detailed change list]
   ```

2. **Update ecosystem documentation**
   ```bash
   # Update ECOSYSTEM.md
   # Update compatibility matrices
   # Update version tracking
   ```

#### 3. Cleanup and Preparation

```bash
# 1. Clean up old branches
git branch -d feature/completed-features
git push origin --delete feature/completed-features

# 2. Update planning for next release
# Create next release planning issue
# Update roadmap documentation

# 3. Monitor deprecation timelines
# Check if any features need deprecation warnings
# Plan removal of deprecated features
```

## Release Checklist Template

### Pre-Release
- [ ] Planning issue created and reviewed
- [ ] All features developed and PRs merged
- [ ] Documentation updated (CHANGELOG, README, migration guides)
- [ ] Testing completed (automated + manual)
- [ ] Breaking changes documented and communicated
- [ ] Dependencies verified and updated

### Release Day
- [ ] Base component (texlive-ja-textlint) tagged and built
- [ ] Docker images published and verified
- [ ] Template environment (latex-environment) updated
- [ ] Core templates updated and tested
- [ ] Release notes published
- [ ] GitHub releases created

### Post-Release
- [ ] End-to-end testing completed
- [ ] User communication sent
- [ ] Documentation updated across ecosystem
- [ ] Issues monitoring in place
- [ ] Next release planning initiated

## Rollback Procedures

### If Critical Issue Discovered

1. **Immediate assessment**
   ```bash
   # Determine scope of impact
   # Identify affected components
   # Assess risk level
   ```

2. **Emergency rollback**
   ```bash
   # Revert latex-environment to previous version
   cd latex-environment/
   git checkout -b emergency-rollback
   # Update image version to previous working version
   git commit -m "EMERGENCY: Rollback to 2025c due to critical issue"
   # Fast-track PR process
   ```

3. **Communication**
   ```bash
   # Immediate notification
   # GitHub Issues in affected repositories
   # Clear description of problem and timeline
   # Provide workarounds if available
   ```

4. **Resolution**
   ```bash
   # Fix issues in new patch release
   # Extra testing before deployment
   # Clear communication about fixes
   ```

## Version Strategy

### Semantic Versioning (latex-environment, templates)
- **MAJOR**: Breaking changes, API changes
- **MINOR**: New features, backward-compatible changes
- **PATCH**: Bug fixes, security updates

### Calendar Versioning (texlive-ja-textlint)
- **YEAR**: Major TeXLive version (2025)
- **LETTER**: Minor updates within year (a, b, c, d)
- **SUFFIX**: Special releases (-hotfix, -security)

### Compatibility Promise
- Support latest 2 major versions
- 1-year overlap for breaking changes
- Clear deprecation warnings 6 months before removal

---

*This process ensures reliable, coordinated releases across the entire ecosystem while maintaining quality and user experience.*