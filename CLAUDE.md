# CLAUDE.md

Ecosystem management repository for the LaTeX thesis environment at Kyushu Sangyo University. Coordinates multiple independent repositories that work together to form a comprehensive academic document management system.

## Quick Start

### Ecosystem Management Commands
```bash
# Show status of all repositories
./ecosystem-manager.sh status

# Check dependency relationships
./ecosystem-manager.sh deps

# Sync all repositories
./ecosystem-manager.sh sync

# Check for uncommitted changes
./ecosystem-manager.sh check
```

### Working with Components
```bash
# Navigate to specific repository
cd latex-environment/      # DevContainer template
cd sotsuron-template/      # Thesis template
cd thesis-management-tools/ # Administrative tools

# Each has its own Git repository and CLAUDE.md
```

## Repository Structure

This directory contains multiple **independent Git repositories**:

- **texlive-ja-textlint/**: Docker images for Japanese LaTeX compilation
- **latex-environment/**: DevContainer template for LaTeX development
- **sotsuron-template/**: Unified thesis template (undergraduate/graduate)
- **thesis-management-tools/**: Administrative tools and workflows
- **aldc/**: Command-line tool for adding LaTeX devcontainer
- **ise-report-template/**: HTML-based report template

## Important Conventions

### This Management Repository
- **Tracks only**: ECOSYSTEM.md, ecosystem-manager.sh, README.md, CLAUDE.md, .claude/
- **Excludes**: All subdirectories (they are independent repositories)
- **Purpose**: Cross-repository coordination and documentation

### Working with Components
- Each subdirectory is an independent Git repository
- Use the appropriate repository's CLAUDE.md for component-specific work
- For ecosystem-wide changes, coordinate through this repository

## Key Workflows

### For Ecosystem-level Changes
1. Work in this management repository
2. Update ECOSYSTEM.md for architectural changes
3. Use ecosystem-manager.sh for coordination

### For Component-specific Changes
1. Navigate to the specific repository directory
2. Use that repository's CLAUDE.md for context
3. Follow that repository's development workflow

## Detailed Documentation

- **[Architecture Guide](docs/CLAUDE-ARCHITECTURE.md)** - Ecosystem structure, dependencies, repository boundaries
- **[Workflows & Examples](docs/CLAUDE-WORKFLOWS.md)** - Detailed command examples, cross-repository coordination