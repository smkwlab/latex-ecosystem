# Dependency Workflow

This document describes the workflow for updating dependencies across the LaTeX thesis environment ecosystem.

## Overview

The ecosystem follows a hierarchical dependency structure:

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
```

## Standard Update Process

### Phase 1: Base Image Update (texlive-ja-textlint)

1. **Create PR with changes**
   ```bash
   cd texlive-ja-textlint/
   git checkout -b feature/update-YYYY
   # Make changes
   git commit -m "Description of changes"
   git push origin feature/update-YYYY
   # Create PR via GitHub
   ```

2. **Test and merge PR**
   - GitHub Actions automatically tests Alpine/Debian/ARM64
   - Review and merge PR

3. **Create release tag**
   ```bash
   git checkout main
   git pull origin main
   git tag YYYY[a-z]  # e.g., 2025d
   git push origin YYYY[a-z]
   ```

4. **Wait for automated build**
   - GitHub Actions builds and publishes Docker images
   - Registry: `ghcr.io/smkwlab/texlive-ja-textlint:YYYY[a-z]`

### Phase 2: Template Environment Update (latex-environment)

1. **Wait for dependency availability**
   ```bash
   # Verify new image is available
   docker pull ghcr.io/smkwlab/texlive-ja-textlint:YYYY[a-z]
   ```

2. **Update devcontainer configuration**
   ```bash
   cd latex-environment/
   git checkout -b update-texlive-YYYY[a-z]
   
   # Update .devcontainer/devcontainer.json
   # - "image": "ghcr.io/smkwlab/texlive-ja-textlint:YYYY[a-z]"
   # - Update version comment
   
   git commit -m "Update texlive-ja-textlint to YYYY[a-z]"
   git push origin update-texlive-YYYY[a-z]
   # Create PR via GitHub
   ```

3. **Test and merge**
   - GitHub Actions tests LaTeX compilation
   - Review and merge PR

4. **Create release**
   ```bash
   git checkout main
   git pull origin main
   git tag v0.X.Y  # Follow semantic versioning
   git push origin v0.X.Y
   ```

### Phase 3: Student Environment Update (latex-environment release branch)

1. **Update latex-environment release branch**
   ```bash
   cd latex-environment/
   git checkout release
   git reset --hard main  # Use latest main branch content
   
   # Remove development-only files for clean student environment
   rm CLAUDE.md DEPENDENCY-UPDATE.md VERSIONS.md CHANGELOG.md VERSION
   rm .github/workflows/check-texlive-updates.yml .github/workflows/create-release.yml
   
   git add -A
   git commit -m "Update release branch to v0.X.Y: texlive-ja-textlint YYYY[a-z]"
   git push origin release --force
   ```

2. **Verify student environment files**
   - `.devcontainer/devcontainer.json` (updated image version)
   - `.github/workflows/autoassingnees.yml` (reviewer assignment)
   - `.github/workflows/latex-build.yml` (PDF generation)
   - `README.md`, `.latexmkrc`, `.textlintrc` (configuration)

3. **Test aldc integration**
   ```bash
   # Test aldc downloads updated environment
   mkdir test-integration && cd test-integration
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/aldc/main/aldc)"
   # Verify .devcontainer uses latest image version
   ```

### Phase 4: Template Repository Notes

**No manual template updates required** - Templates automatically receive updates through aldc:

- **sotsuron-template**: No .devcontainer directory (added by aldc)
- **latex-template**: No .devcontainer directory (added by aldc) 
- **wr-template**: No .devcontainer directory (added by aldc)
- **sotsuron-report-template**: No .devcontainer directory (added by aldc)

**Student workflow**: When students create repositories using thesis-management-tools, aldc automatically integrates the latest latex-environment release branch content.

## Automated vs Manual Steps

### ✅ Automated (GitHub Actions)
- Docker image building and publishing
- LaTeX compilation testing
- Multi-architecture builds
- Security scanning

### 🔧 Manual Steps Required
- PR creation and review
- Tag creation and pushing
- Cross-repository coordination
- Documentation updates
- Breaking change communication

## Emergency Updates

For critical security updates or bug fixes:

### Fast Track Process
1. **Immediate base image fix**
   ```bash
   cd texlive-ja-textlint/
   git checkout -b hotfix/critical-fix
   # Apply fix
   git commit -m "HOTFIX: Critical security/bug fix"
   # Create PR with HOTFIX label
   ```

2. **Expedited review and merge**
   - Skip normal review cycle for critical issues
   - Fast-track testing

3. **Emergency release**
   ```bash
   git tag YYYY[a-z]-hotfix
   git push origin YYYY[a-z]-hotfix
   ```

4. **Coordinate downstream updates**
   - Notify all maintainers
   - Prioritize latex-environment update
   - Document emergency process in changelogs

## Version Coordination

### Naming Conventions
- **texlive-ja-textlint**: Calendar versioning (2025, 2025a, 2025b, etc.)
- **latex-environment**: Semantic versioning (v0.5.0, v0.5.1, etc.)
- **Templates**: Semantic versioning or date-based as appropriate

### Compatibility Matrix
Maintain compatibility information in:
- `latex-environment/VERSIONS.md`
- `ECOSYSTEM.md` (this repository)
- Individual template README files

### Breaking Changes
1. **Announce in advance**
   - Create issues in affected repositories
   - Update documentation
   - Provide migration guides

2. **Staged rollout**
   - New versions available alongside old
   - Gradual migration over 2-3 release cycles
   - Clear deprecation timeline

3. **Support matrix**
   - Maintain compatibility for at least 1 major version
   - Document end-of-life timelines

## Rollback Procedures

### If New Version Causes Issues

1. **Immediate response**
   ```bash
   # Revert to previous working version
   cd latex-environment/
   git checkout -b revert-to-YYYY[x]
   # Update image version to previous working version
   git commit -m "REVERT: Rollback to YYYY[x] due to issues"
   ```

2. **Communication**
   - Create issues in affected repositories
   - Notify user community
   - Document known problems

3. **Fix and re-release**
   - Address issues in new patch version
   - Test thoroughly before re-deployment

## Quality Gates

### Before Each Phase
- [ ] All automated tests pass
- [ ] Manual testing completed
- [ ] Documentation updated
- [ ] Breaking changes documented
- [ ] Rollback plan prepared

### Release Checklist
- [ ] Docker images published and accessible
- [ ] GitHub releases created with proper notes
- [ ] Compatibility matrix updated
- [ ] Downstream repositories notified
- [ ] User-facing documentation updated

## Tools and Automation

### Ecosystem Manager Script
```bash
# Check status across all repositories
./ecosystem-manager.sh status

# Check for needed updates
./ecosystem-manager.sh check-updates

# Verify compatibility
./ecosystem-manager.sh verify-versions
```

### Dependency Tracking
- Monitor upstream TeXLive releases
- Track Node.js and npm package updates
- Watch for security advisories

## Communication Channels

### Internal Coordination
- GitHub Issues for planning
- PR descriptions for detailed changes
- Commit messages following conventional commits

### User Communication
- GitHub Releases for version announcements
- README updates for migration guides
- CHANGELOG files for detailed changes

---

*This workflow ensures systematic, safe updates across the entire ecosystem while maintaining quality and minimizing disruption to users.*