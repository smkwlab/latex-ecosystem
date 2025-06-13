# LaTeX Ecosystem Setup Guide

This guide explains how to set up the complete LaTeX ecosystem development environment for Shimokawa Lab, Faculty of Science and Engineering, Kyushu Sangyo University.

## Prerequisites

- Git
- GitHub CLI (`gh`) - Recommended for easier authentication and cloning
- Docker (optional, for testing)
- VSCode (recommended for development)

## Quick Setup

```bash
# One-line setup (coming soon)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/latex-ecosystem/main/setup.sh)"
```

## Manual Setup

### 1. Create Ecosystem Directory

```bash
# Create and navigate to ecosystem directory
mkdir latex-ecosystem-dev
cd latex-ecosystem-dev

# Clone the ecosystem management repository
gh repo clone smkwlab/latex-ecosystem .
# Or without gh:
# git clone https://github.com/smkwlab/latex-ecosystem.git .
```

### 2. Clone All Repositories

Using GitHub CLI (recommended):
```bash
# Core infrastructure
gh repo clone smkwlab/texlive-ja-textlint
gh repo clone smkwlab/latex-environment
gh repo clone smkwlab/latex-release-action

# Templates
gh repo clone smkwlab/sotsuron-template
gh repo clone smkwlab/wr-template
gh repo clone smkwlab/latex-template
gh repo clone smkwlab/sotsuron-report-template

# Management tools
gh repo clone smkwlab/thesis-management-tools
gh repo clone smkwlab/ai-academic-paper-reviewer
gh repo clone smkwlab/aldc
```

Or using git directly:
```bash
# Core infrastructure
git clone git@github.com:smkwlab/texlive-ja-textlint.git
git clone git@github.com:smkwlab/latex-environment.git
git clone git@github.com:smkwlab/latex-release-action.git

# Templates
git clone git@github.com:smkwlab/sotsuron-template.git
git clone git@github.com:smkwlab/wr-template.git
git clone git@github.com:smkwlab/latex-template.git
git clone git@github.com:smkwlab/sotsuron-report-template.git

# Management tools
git clone git@github.com:smkwlab/thesis-management-tools.git
git clone git@github.com:smkwlab/ai-academic-paper-reviewer.git
git clone git@github.com:smkwlab/aldc.git
```

### 3. Verify Setup

```bash
# Check ecosystem status
./ecosystem-manager.sh status

# Check versions
./ecosystem-manager.sh versions

# Check dependencies
./ecosystem-manager.sh deps
```

## Development Workflow

### Daily Tasks

```bash
# Check for updates
./ecosystem-manager.sh check

# Sync all repositories
./ecosystem-manager.sh sync

# Check CLAUDE.md status
./ecosystem-manager.sh claude-status
```

### Making Changes

1. **Update dependency chain**:
   ```
   texlive-ja-textlint → latex-environment → templates
   ```

2. **Test changes**:
   ```bash
   # Run integration tests
   ./ecosystem-manager.sh test
   ```

3. **Update documentation**:
   ```bash
   # Sync ECOSYSTEM.md to all repos
   ./ecosystem-manager.sh sync-docs
   ```

## Repository Structure

After setup, your directory structure will be:

```
latex-ecosystem-dev/
├── .git/                    # Git repository (latex-ecosystem)
├── ECOSYSTEM.md             # Ecosystem documentation
├── ecosystem-manager.sh     # Management script
├── SETUP.md                 # Setup guide
├── setup.sh                 # Automated setup script
├── texlive-ja-textlint/     # Docker base images
├── latex-environment/       # DevContainer template
├── latex-release-action/    # CI/CD action
├── sotsuron-template/       # Thesis template
├── wr-template/             # Weekly report template
├── latex-template/          # Basic template
├── sotsuron-report-template/ # Report template
├── thesis-management-tools/ # Admin tools
├── ai-academic-paper-reviewer/ # AI reviewer
└── aldc/                    # Environment installer
```

Note: The base directory itself is the latex-ecosystem repository, containing management tools and documentation.

## Troubleshooting

### Permission Denied
```bash
# Fix permissions
chmod +x ecosystem-manager.sh
```

### Clone Failed
```bash
# If using gh, check authentication
gh auth status
gh auth login

# Check SSH keys (for git clone)
ssh -T git@github.com

# Use HTTPS instead
git clone https://github.com/smkwlab/...
```

### Missing Dependencies
```bash
# Install GitHub CLI
# macOS
brew install gh

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
```

## Contributing

When contributing to the ecosystem:

1. Read `ECOSYSTEM.md` for overview
2. Check repository-specific `CLAUDE.md`
3. Follow version management guidelines
4. Test changes across dependent repositories
5. Update documentation as needed

## Advanced Setup Options

### Custom Directory Structure
```bash
# Set custom base directory
export LATEX_ECOSYSTEM_BASE=/path/to/your/dir
./setup.sh
```

### Selective Repository Setup
```bash
# Clone only specific repositories
./setup.sh --only core      # Core infrastructure only
./setup.sh --only templates  # Templates only
./setup.sh --only tools      # Tools only
```