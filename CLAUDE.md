# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the LaTeX thesis environment ecosystem.

## Repository Overview

This is the **ecosystem management repository** for the LaTeX thesis environment at Kyushu Sangyo University. It contains documentation and management tools for coordinating multiple independent repositories that work together to form a comprehensive academic document management system.

## Repository Structure

This directory contains multiple **independent Git repositories**, each with their own version control:

- **texlive-ja-textlint/**: Docker images for Japanese LaTeX compilation
- **latex-environment/**: DevContainer template for LaTeX development
- **sotsuron-template/**: Unified thesis template (undergraduate/graduate)
- **thesis-management-tools/**: Administrative tools and workflows
- **latex-release-action/**: GitHub Action for LaTeX compilation
- **ai-academic-paper-reviewer/**: GitHub Action for automated paper review
- **aldc/**: Command-line tool for adding LaTeX devcontainer
- **wr-template/**: Weekly report template
- **latex-template/**: Basic LaTeX template
- **sotsuron-report-template/**: Report template

## Key Commands

### Ecosystem Management
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

### Working with Individual Repositories
```bash
# Navigate to specific repository
cd latex-environment/
cd sotsuron-template/
cd thesis-management-tools/

# Each has its own Git repository and CLAUDE.md
```

## Important Conventions

### This Management Repository
- **Tracks only**: ECOSYSTEM.md, ecosystem-manager.sh, README.md, CLAUDE.md, .claude/
- **Excludes**: All subdirectories (they are independent repositories)
- **Purpose**: Cross-repository coordination and documentation

### Working with Components
- Each subdirectory is an independent Git repository
- Use the appropriate repository's CLAUDE.md for component-specific work
- For ecosystem-wide changes, coordinate through this repository

### Git Repository Boundaries
```
thesis-environment/           # This management repository
├── .git/                    # Git for management files only
├── ECOSYSTEM.md             # Tracked
├── ecosystem-manager.sh     # Tracked
├── CLAUDE.md               # Tracked (this file)
├── .claude/                # Tracked
│
├── latex-environment/      # Independent repository
│   ├── .git/              # Separate Git repository
│   ├── CLAUDE.md          # Different CLAUDE.md for that repo
│   └── ...
│
├── sotsuron-template/      # Independent repository
│   ├── .git/              # Separate Git repository
│   ├── CLAUDE.md          # Different CLAUDE.md for that repo
│   └── ...
│
└── (other independent repos...)
```

## Workflow Guidelines

### For Ecosystem-level Changes
1. Work in this management repository
2. Update ECOSYSTEM.md for architectural changes
3. Use ecosystem-manager.sh for coordination
4. Create issues in relevant component repositories

### For Component-specific Changes
1. Navigate to the specific repository directory
2. Use that repository's CLAUDE.md for context
3. Work within that repository's conventions
4. Follow that repository's development workflow

### For Cross-repository Issues
1. Document the issue in ECOSYSTEM.md
2. Create coordinated issues in affected repositories
3. Use ecosystem-manager.sh to track status
4. Test changes across the ecosystem

## Architecture Understanding

### Dependency Chain
- **texlive-ja-textlint** → **latex-environment** → **templates**
- **Supporting tools** integrate with templates and environments
- **Management tools** coordinate the entire ecosystem

### Version Coordination
- Each repository has independent versioning
- Compatibility matrices documented in ECOSYSTEM.md
- Automated update chains where appropriate

### Student Workflow
- Students create repositories using automated tools
- They receive clean templates without management overhead
- Faculty use review workflows for supervision

## Important Notes

- **Multiple Git Repositories**: Each subdirectory has its own .git/ and version control
- **Different CLAUDE.md Files**: Each repository has its own Claude instructions
- **Ecosystem Coordination**: Use this repository for cross-cutting concerns
- **Independent Development**: Component changes happen in their respective repositories

## Shell Command Gotchas

### Directory Navigation
```bash
# Working in ecosystem management
pwd  # /path/to/thesis-environment (management repo)

# Working in component
cd latex-environment/
pwd  # /path/to/thesis-environment/latex-environment (different repo)
git status  # Shows latex-environment repository status

cd ..
git status  # Shows management repository status
```

### Git Operations
```bash
# Management repository operations
git add ECOSYSTEM.md
git commit -m "Update ecosystem docs"

# Component repository operations  
cd latex-environment/
git add .devcontainer/devcontainer.json
git commit -m "Update devcontainer config"
cd ..

# These are completely separate Git repositories
```