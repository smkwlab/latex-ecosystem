# CLAUDE.md

Ecosystem management repository for the LaTeX thesis environment at Kyushu Sangyo University. Provides comprehensive academic document management system with Pull Request-based review workflow for thesis writing support.

## System Purpose

This ecosystem supports **thesis writing with LaTeX** through a structured learning approach:

1. **Weekly Reports** (wr-template) → Learn LaTeX basics
2. **Thesis Reports** (sotsuron-report-template) → Practice LaTeX formatting  
3. **ISE Reports** (ise-report-template) → Learn Pull Request-based review
4. **Final Thesis** (sotsuron-template) → Complete thesis with full review workflow

All documents use **Pull Request-based review** for collaborative improvement and educational feedback.

## Quick Start

### Ecosystem Management Commands

The manager is an Elixir escript. Build it once with
`(cd ecosystem-manager && mix escript.build)`, then:

```bash
# Show status of all repositories (default command)
./ecosystem-manager/ecosystem-manager status

# Detailed status: branch, uncommitted changes, last commit, PRs, issues
./ecosystem-manager/ecosystem-manager status --long

# Fast status without GitHub API calls
./ecosystem-manager/ecosystem-manager status --fast

# Show only repositories with urgent issues / open PRs / PRs needing review
./ecosystem-manager/ecosystem-manager status --urgent-issues
./ecosystem-manager/ecosystem-manager status --with-prs
./ecosystem-manager/ecosystem-manager status --needs-review

# Show repository configuration and sources
./ecosystem-manager/ecosystem-manager repos

# Show current configuration
./ecosystem-manager/ecosystem-manager config
```

### Working with Components
```bash
# Navigate to specific repository
cd latex-environment/      # DevContainer template
cd sotsuron-template/      # Thesis template
cd student-repo-management/ # Administrative tools

# Each has its own Git repository and CLAUDE.md
```

## Repository Structure

This directory contains multiple **independent Git repositories**:

### Core Infrastructure
- **texlive-ja-textlint/**: Docker images for Japanese LaTeX compilation
- **latex-environment/**: DevContainer template for LaTeX development
- **aldc/**: Command-line tool for adding LaTeX devcontainer to templates

### Document Templates
- **sotsuron-template/**: Thesis template (undergraduate/graduate) with PR review workflow
- **wr-template/**: Weekly report template for LaTeX learning
- **sotsuron-report-template/**: Thesis report template for practice
- **ise-report-template/**: ISE report template for PR review learning
- **latex-template/**: General-purpose LaTeX template
- **poster-template/**: Academic poster template (A0 size)

### Management & Monitoring
- **ecosystem-manager/**: Cross-repository status tool for the ecosystem workspace (Elixir escript, separate repo)
- **student-repo-management/**: Repository creation and branch protection automation
- **thesis-student-registry/**: Secure student repository registry data (private, data-only)
- **registry-manager/**: Registry data management tool (Elixir escript, separate repo)
- **thesis-monitor/**: Student repository monitoring tool (Elixir escript, separate repo)
- **latex-ecosystem/**: This management repository for ecosystem coordination

### GitHub Actions
- **ai-academic-paper-reviewer/**: AI review action (ACADEMIC/CODE modes); the single AI reviewer for the ecosystem
- **latex-release-action/**: PDF generation and release automation
- **ai-reviewer/** (legacy): standalone code-review action, superseded by ai-academic-paper-reviewer (CODE mode); no longer used, kept for reference only

## Important Conventions

### This Management Repository
- **Tracks**: ECOSYSTEM.md, README.md, CLAUDE.md, .claude/, docs/
- **Excludes**: All subdirectories except docs/ (they are independent repositories, including ecosystem-manager/)
- **Purpose**: Cross-repository coordination and documentation

### Working with Components
- Each subdirectory is an independent Git repository
- Use the appropriate repository's CLAUDE.md for component-specific work
- For ecosystem-wide changes, coordinate through this repository

## Key Workflows

Student repository creation and progress-monitoring command examples live in
[docs/MANAGEMENT-WORKFLOWS.md](docs/MANAGEMENT-WORKFLOWS.md) (Student Repository Workflows section).

### For Ecosystem-level Changes
1. Work in this management repository
2. Update ECOSYSTEM.md for architectural changes
3. Use ecosystem-manager/ecosystem-manager for coordination

### For Component-specific Changes
1. Navigate to the specific repository directory
2. Use that repository's CLAUDE.md for context
3. Follow that repository's development workflow

### Updating Workflow Files in Student Repositories

**IMPORTANT**: Student repositories use draft-to-draft PR workflow (`2nd-draft` → `1st-draft` → `0th-draft` → `main`). Workflow changes must be propagated through the branch hierarchy via merge — pushing identical changes independently to each branch makes workflow diffs appear in PRs, which triggers GitHub Actions security restrictions and skips `pull_request` workflows.

Use the **`/propagate` skill** ([.claude/skills/propagate/SKILL.md](.claude/skills/propagate/SKILL.md)) for the full procedure: registry-manager setup check → dry-run → `propagate-workflow` execution → PR diff verification, including the manual merge-chain fallback.

## Security & Data Management

- **Registry Data Separation**: student information lives only in the private registry data repository (`thesis-student-registry`), separate from tools and templates
- **Automated Registry Updates**: GitHub Actions automatically update the registry (`data/registry.json`)
- **Branch Protection**: Automatic setup for PR-based review workflows
- **Access Control**: Fine-grained permissions for different user roles

## Detailed Documentation

- **[Getting Started](docs/GETTING-STARTED.md)** - Single-path guide for starting ecosystem operations
- **[ECOSYSTEM.md](ECOSYSTEM.md)** - Ecosystem-wide architecture, dependencies, version compatibility
- **[Management Repository Guide](docs/MANAGEMENT-REPOSITORY.md)** - This management repository's structure and boundaries
- **[Workflows & Examples](docs/MANAGEMENT-WORKFLOWS.md)** - Detailed command examples, cross-repository coordination

## Development Notes

- **ai-academic-paper-reviewer**: Developed based on `ai-reviewer`; now the single AI reviewer (ACADEMIC/CODE modes)
- **ai-reviewer** (legacy): superseded by ai-academic-paper-reviewer, no longer used by migrated workflows; kept for reference only
- **thesis-monitor**: Elixir-based monitoring tool with CSV integration (own repository: smkwlab/thesis-monitor)
- **Cross-repository Coordination**: All repositories work together as unified system