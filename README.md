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
# Everything above is tracked by this management repository
# (ecosystem_manager is part of it, not cloned).
# Everything below is a separate repository cloned by setup.sh:
#
#   Core infrastructure
├── texlive-ja-textlint/      # Docker images for Japanese LaTeX + textlint
├── latex-environment/        # DevContainer template
├── latex-release-action/     # PDF build / release GitHub Action
#
#   Document templates
├── sotsuron-template/        # Thesis (undergraduate + graduate)
├── ise-report-template/      # ISE report (HTML/textlint)
├── wr-template/              # Weekly report
├── latex-template/           # General-purpose LaTeX
├── sotsuron-report-template/ # Thesis report
├── poster-template/          # Academic poster (A0)
#
#   Management & automation
├── student-repo-management/  # Repository creation / review tooling
├── thesis-student-registry/  # Student repository registry data (private, data-only)
├── ai-academic-paper-reviewer/ # AI review Action (ACADEMIC/CODE modes)
└── aldc/                     # Adds the LaTeX devcontainer to a repository
```

## Prerequisites

### Required Tools

- **Git**: Version control system
- **GitHub CLI (gh)**: Required for PR/Issue tracking features
- **Elixir 1.17+** (with Erlang/OTP): Required to build and run the ecosystem-manager escript
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
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/student-repo-management/v1/create-repo/setup.sh)"
```

**With student ID specified:**
```bash
STUDENT_ID=k21rs001 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/student-repo-management/v1/create-repo/setup.sh)"
```

### For Faculty

Review workflow documentation is available in `student-repo-management/docs/`.

## Documentation

- **[docs/README.md](docs/README.md)**: Documentation guide — start here to find the right document for your role
- **[docs/GETTING-STARTED.md](docs/GETTING-STARTED.md)**: Single-path guide for starting ecosystem operations
- **[ECOSYSTEM.md](ECOSYSTEM.md)**: Comprehensive ecosystem architecture and management guide
- **[docs/](docs/)**: Detailed documentation
  - **[SETUP-AND-RELEASE.md](docs/SETUP-AND-RELEASE.md)**: Comprehensive setup, dependency management, and release processes
  - **[MANAGEMENT-REPOSITORY.md](docs/MANAGEMENT-REPOSITORY.md)**: This management repository's structure and boundaries (ecosystem-wide architecture is in ECOSYSTEM.md above)
  - **[MANAGEMENT-WORKFLOWS.md](docs/MANAGEMENT-WORKFLOWS.md)**: Ecosystem management workflows and coordination
  - **[GIT-WORKFLOW.md](docs/GIT-WORKFLOW.md)**: Git best practices and conflict resolution
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
├── ise-report-template (HTML-based quality-focused)
├── wr-template
├── latex-template
├── sotsuron-report-template
└── poster-template

Supporting Infrastructure:
├── latex-release-action → (Used by templates)
├── ai-academic-paper-reviewer → (AI review for thesis repos & code review, ACADEMIC/CODE modes)
├── aldc → latex-environment (release branch)
├── student-repo-management → (Management workflows)
└── thesis-student-registry → (Student repository registry data; managed by registry-manager, read by thesis-monitor)
```

## Support

- **Component Issues**: Create issues in the relevant repository
- **Ecosystem Issues**: Create issues in the most relevant component repository
- **Documentation**: Refer to ECOSYSTEM.md for detailed information

---

*For detailed architecture information, see [ECOSYSTEM.md](ECOSYSTEM.md)*