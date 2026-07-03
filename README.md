# LaTeX Ecosystem

Comprehensive ecosystem management for LaTeX thesis templates and tools at Shimokawa Lab, Faculty of Science and Engineering, Kyushu Sangyo University.

## Repository Structure

This directory contains multiple independent Git repositories that work together to form a comprehensive LaTeX academic document management system:

```
latex-ecosystem/
├── ECOSYSTEM.md              # This management repository
├── ecosystem_manager/        # Cross-repository management tool (Elixir escript)
├── setup.sh                  # Automated setup script
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
├── sotsuron-report-template/ # Independent Git repository
└── poster-template/          # Independent Git repository
```

## Prerequisites

### Required Tools

- **Git**: Version control system
- **GitHub CLI (gh)**: Required for PR/Issue tracking features
- **Elixir/Mix** (with Erlang/OTP): Required to build and run the ecosystem-manager escript
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

**Note**: Some ecosystem repositories (e.g. `thesis-student-registry`) are private. `setup.sh` can clone them only with an authenticated GitHub CLI (`gh auth login`) or an SSH key registered on GitHub; the anonymous HTTPS fallback works for public repositories only.

## Quick Start

### Initial Setup

**One-line setup:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/latex-ecosystem/main/setup.sh)"
```

This creates a `latex-ecosystem-dev/` directory under the current directory
and sets up everything inside it.

**Manual clone and setup:**
```bash
gh repo clone smkwlab/latex-ecosystem latex-ecosystem-dev
cd latex-ecosystem-dev
./setup.sh
```

When run inside an existing latex-ecosystem checkout, `setup.sh` detects it
and clones the component repositories into that checkout instead of creating
a nested `latex-ecosystem-dev/`.

**Custom location:**
```bash
# Set LATEX_ECOSYSTEM_BASE to control where the ecosystem is set up
LATEX_ECOSYSTEM_BASE="$HOME/work/latex-ecosystem" \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/latex-ecosystem/main/setup.sh)"
```

### Daily Ecosystem Management

> **First time?** Build the escript once: `(cd ecosystem_manager && mix escript.build)`

```bash
# Check status of all repositories
./ecosystem_manager/ecosystem-manager status

# Detailed status (branch, uncommitted changes, last commit, PRs, issues)
./ecosystem_manager/ecosystem-manager status --long

# Fast status without GitHub API calls
./ecosystem_manager/ecosystem-manager status --fast

# Show repository configuration and sources
./ecosystem_manager/ecosystem-manager repos
```

### For Students

Students should use the automated repository creation process:

**Basic setup (zero dependencies required):**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/thesis-management-tools/v1/create-repo/setup.sh)"
```

**With student ID specified:**
```bash
STUDENT_ID=k21rs001 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/thesis-management-tools/v1/create-repo/setup.sh)"
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
- **ecosystem_manager/**: Cross-repository management tool (Elixir escript)
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
2. Use ecosystem_manager/ecosystem-manager to coordinate changes
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
├── sotsuron-report-template
└── poster-template

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