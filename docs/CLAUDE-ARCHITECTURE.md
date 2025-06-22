# Ecosystem Architecture Guide

This document covers the architecture, dependencies, and coordination patterns for the LaTeX thesis environment ecosystem.

## Architecture Overview

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

## Git Repository Boundaries

### Management Repository Structure
```
latex-ecosystem/                 # This management repository
├── .git/                       # Git for management files only
├── ECOSYSTEM.md                # Tracked - ecosystem overview
├── ecosystem-manager.sh        # Tracked - coordination scripts
├── CLAUDE.md                   # Tracked - this file
├── .claude/                    # Tracked - claude configuration
├── docs/                       # Tracked - ecosystem documentation
│   ├── CLAUDE-ARCHITECTURE.md  # This file
│   └── CLAUDE-WORKFLOWS.md     # Workflow examples
│
├── latex-environment/          # Independent repository
│   ├── .git/                  # Separate Git repository
│   ├── CLAUDE.md              # Different CLAUDE.md for that repo
│   └── docs/                  # Component-specific documentation
│
├── sotsuron-template/          # Independent repository
│   ├── .git/                  # Separate Git repository
│   ├── CLAUDE.md              # Different CLAUDE.md for that repo
│   └── docs/                  # Component-specific documentation
│
└── (other independent repos...)
```

### Repository Categories

#### Core Infrastructure
- **texlive-ja-textlint/**: Docker images for Japanese LaTeX compilation
- **latex-environment/**: DevContainer template for LaTeX development

#### Templates
- **sotsuron-template/**: Unified thesis template (undergraduate/graduate)
- **wr-template/**: Weekly report template
- **latex-template/**: Basic LaTeX template
- **ise-report-template/**: HTML-based report template

#### Tools and Automation
- **thesis-management-tools/**: Administrative tools and workflows
- **latex-release-action/**: GitHub Action for LaTeX compilation
- **ai-academic-paper-reviewer/**: GitHub Action for automated paper review
- **aldc/**: Command-line tool for adding LaTeX devcontainer

## Design Principles

### Management Repository Principles
- **Tracks files only**: No subdirectory content except docs/
- **Coordination focus**: Cross-repository coordination and documentation
- **Independent components**: Each subdirectory is a separate Git repository
- **Exception for docs/**: Ecosystem-wide documentation is centrally managed

### Component Repository Principles
- **Independent versioning**: Each has its own release cycle
- **Self-contained**: Complete functionality within each repository
- **Coordinated updates**: Use ecosystem management for compatibility
- **Consistent structure**: Follow established patterns (CLAUDE.md, docs/, etc.)

## Ecosystem Coordination

### Cross-repository Dependencies
```
texlive-ja-textlint (base images)
    ↓
latex-environment (devcontainer)
    ↓
sotsuron-template, wr-template, etc. (templates)
    ↓
thesis-management-tools (student workflows)
```

### Update Propagation
1. **Base layer changes** (texlive-ja-textlint) → Test with latex-environment
2. **Environment changes** (latex-environment) → Update dependent templates
3. **Template changes** → Coordinate with management tools
4. **Tool changes** → Validate with existing templates

### Compatibility Management
- **Version matrices**: Documented in ECOSYSTEM.md
- **Testing coordination**: Use ecosystem-manager.sh for validation
- **Breaking change communication**: Cross-repository issue coordination