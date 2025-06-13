# LaTeX Ecosystem

Comprehensive ecosystem management for LaTeX thesis templates and tools at Shimokawa Lab, Faculty of Science and Engineering, Kyushu Sangyo University.

## Repository Structure

This directory contains multiple independent Git repositories that work together to form a comprehensive LaTeX academic document management system:

```
thesis-environment/
├── ECOSYSTEM.md              # This management repository
├── ecosystem-manager.sh      # Cross-repository management script
├── README.md                 # This file
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

## Quick Start

### Initial Setup

```bash
# One-line setup
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/latex-ecosystem/main/setup.sh)"

# Or clone and setup manually
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

```bash
# Create your thesis repository (zero dependencies required)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/thesis-management-tools/main/create-repo/setup.sh)"

# With student ID
STUDENT_ID=k21rs001 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/thesis-management-tools/main/create-repo/setup.sh)"
```

### For Faculty

Review workflow documentation is available in `thesis-management-tools/docs/`.

## Documentation

- **[ECOSYSTEM.md](ECOSYSTEM.md)**: Comprehensive ecosystem architecture and management guide
- **[SETUP.md](SETUP.md)**: Detailed setup instructions
- **Individual repositories**: Each has its own README.md and CLAUDE.md documentation

## Repository Management

### This Repository (latex-ecosystem)

This management repository contains:
- **ECOSYSTEM.md**: Comprehensive ecosystem architecture documentation
- **SETUP.md**: Setup guide for developers
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