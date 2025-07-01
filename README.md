# LaTeX Ecosystem

Comprehensive ecosystem management for LaTeX thesis templates and tools at Shimokawa Lab, Faculty of Science and Engineering, Kyushu Sangyo University.

## Repository Structure

This directory contains multiple independent Git repositories that work together to form a comprehensive LaTeX academic document management system:

```
latex-ecosystem/
├── ECOSYSTEM.md              # This management repository
├── ecosystem-manager.sh      # Cross-repository management script
├── README.md                 # This file
├── docs/                     # Detailed documentation
│
├── texlive-ja-textlint/      # Independent Git repository
├── latex-environment/        # Independent Git repository  
├── sotsuron-template/        # Independent Git repository
├── thesis-management-tools/  # Independent Git repository
├── latex-release-action/     # Independent Git repository
├── ai-academic-paper-reviewer/ # Independent Git repository
├── aldc/                     # Independent Git repository
├── wr-template/              # Independent Git repository
├── latex-template/           # Independent Git repository
└── sotsuron-report-template/ # Independent Git repository
```

## Prerequisites

### Required Tools

- **Git**: Version control system
- **GitHub CLI (gh)**: Required for PR/Issue tracking features
- **jq**: JSON processor for parsing API responses
- **Bash**: Shell interpreter (version 4.0+)

### GitHub CLI Setup

The ecosystem manager uses GitHub CLI for advanced features. To get full functionality:

```bash
# Install GitHub CLI (if not already installed)
# macOS
brew install gh

# Ubuntu/Debian
sudo apt install gh

# Other platforms: see https://cli.github.com/

# Authenticate with GitHub
gh auth login

# Verify authentication
gh auth status
```

**Note**: Without GitHub CLI authentication, the ecosystem manager will still work but with limited functionality (no PR/Issue counts).

## Quick Start

### Initial Setup

**One-line setup:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/latex-ecosystem/main/setup.sh)"
```

**Manual clone and setup:**
```bash
gh repo clone smkwlab/latex-ecosystem latex-ecosystem-dev
cd latex-ecosystem-dev
./setup.sh
```

### Daily Ecosystem Management

```bash
# Check status of all repositories
./ecosystem-manager.sh status

# Show dependency relationships
./ecosystem-manager.sh deps

# Check CLAUDE.md tracking across repos
./ecosystem-manager.sh claude-status

# Sync all repositories
./ecosystem-manager.sh sync
```

### For Students

Students should use the automated repository creation process:

**Basic setup (zero dependencies required):**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/thesis-management-tools/main/create-repo/setup.sh)"
```

**With student ID specified:**
```bash
STUDENT_ID=k21rs001 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/thesis-management-tools/main/create-repo/setup.sh)"
```

### For Faculty

Review workflow documentation is available in `thesis-management-tools/docs/`.

## Documentation

- **[ECOSYSTEM.md](ECOSYSTEM.md)**: Comprehensive ecosystem architecture and management guide
- **[docs/](docs/)**: Detailed documentation
  - **[CLAUDE-SETUP.md](docs/CLAUDE-SETUP.md)**: Comprehensive setup, dependency management, and release processes
  - **[CLAUDE-ARCHITECTURE.md](docs/CLAUDE-ARCHITECTURE.md)**: Architecture guide and repository boundaries
  - **[CLAUDE-WORKFLOWS.md](docs/CLAUDE-WORKFLOWS.md)**: Ecosystem management workflows and coordination
  - **[CLAUDE-GIT-WORKFLOW.md](docs/CLAUDE-GIT-WORKFLOW.md)**: Git best practices and conflict resolution
- **Individual repositories**: Each has its own README.md and CLAUDE.md documentation

## Repository Management

### This Repository (latex-ecosystem)

This management repository contains:
- **ECOSYSTEM.md**: Comprehensive ecosystem architecture documentation
- **docs/**: Detailed documentation directory with specialized guides
- **ecosystem-manager.sh**: Cross-repository management script
- **setup.sh**: Automated setup script for cloning all repositories
- **README.md**: This overview file

All subdirectories are independent Git repositories cloned by setup.sh and are **not** included in this repository's version control.

### Individual Repositories

Each subdirectory is a separate Git repository with its own:
- Independent version control
- GitHub repository and issues
- Release cycles and tagging
- Documentation and README

## Contributing

### For Ecosystem-wide Changes

1. Update documentation in this repository
2. Use ecosystem-manager.sh to coordinate changes
3. Create issues in relevant individual repositories
4. Test changes across the ecosystem

### For Component-specific Changes

Work directly in the relevant repository following its contribution guidelines.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Dependency Flow                         │
└─────────────────────────────────────────────────────────────┘

texlive-ja-textlint (Docker Base)
    ↓
latex-environment (DevContainer Template)
    ↓
├── sotsuron-template (Student Templates)
├── wr-template
├── latex-template
└── sotsuron-report-template

Supporting Infrastructure:
├── latex-release-action → (Used by templates)
├── ai-academic-paper-reviewer → (Used by thesis repos)  
├── aldc → latex-environment (release branch)
└── thesis-management-tools → (Management workflows)
```

## Support

- **Component Issues**: Create issues in the relevant repository
- **Ecosystem Issues**: Create issues in the most relevant component repository
- **Documentation**: Refer to ECOSYSTEM.md for detailed information

---

*For detailed architecture information, see [ECOSYSTEM.md](ECOSYSTEM.md)*