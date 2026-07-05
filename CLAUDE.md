# CLAUDE.md

Ecosystem management repository for the LaTeX thesis environment at Kyushu Sangyo University. Provides comprehensive academic document management system with Pull Request-based review workflow for thesis writing support.

## System Purpose

This ecosystem supports **thesis writing with LaTeX** through a structured learning approach:

1. **Weekly Reports** (wr-template) → Learn LaTeX basics
2. **Thesis Reports** (sotsuron-report-template) → Practice LaTeX formatting  
3. **ISE Reports** (ise-report-template) → Learn Pull Request-based review
4. **Final Thesis** (sotsuron-template) → Complete thesis with full review workflow

All documents use **Pull Request-based review** for collaborative improvement and educational feedback.

## Educational Philosophy

The system implements a **progressive learning approach**:

- **Step 1**: Students practice LaTeX with weekly reports
- **Step 2**: Students create thesis reports to learn document structure  
- **Step 3**: Students learn collaborative review through ISE reports
- **Step 4**: Students write thesis with full PR-based review support

Each step builds upon previous knowledge while introducing new collaborative writing skills.

## Quick Start

### Ecosystem Management Commands

The manager is an Elixir escript. Build it once with
`(cd ecosystem_manager && mix escript.build)`, then:

```bash
# Show status of all repositories (default command)
./ecosystem_manager/ecosystem-manager status

# Detailed status: branch, uncommitted changes, last commit, PRs, issues
./ecosystem_manager/ecosystem-manager status --long

# Fast status without GitHub API calls
./ecosystem_manager/ecosystem-manager status --fast

# Show only repositories with urgent issues / open PRs / PRs needing review
./ecosystem_manager/ecosystem-manager status --urgent-issues
./ecosystem_manager/ecosystem-manager status --with-prs
./ecosystem_manager/ecosystem-manager status --needs-review

# Show repository configuration and sources
./ecosystem_manager/ecosystem-manager repos

# Show current configuration
./ecosystem_manager/ecosystem-manager config
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

### Management & Monitoring
- **thesis-management-tools/**: Repository creation and branch protection automation
- **thesis-student-registry/**: Secure student repository registry data (private, data-only)
- **registry-manager/**: Registry data management tool (Elixir escript, separate repo)
- **thesis-monitor/**: Student repository monitoring tool (Elixir escript, separate repo)
- **latex-ecosystem/**: This management repository for ecosystem coordination

### GitHub Actions
- **ai-reviewer/**: Automated PR review action (bug-fixed fork)
- **ai-academic-paper-reviewer/**: Academic paper review action
- **latex-release-action/**: PDF generation and release automation

## Important Conventions

### This Management Repository
- **Tracks**: ECOSYSTEM.md, ecosystem_manager/, README.md, CLAUDE.md, .claude/, docs/
- **Excludes**: All subdirectories except docs/ (they are independent repositories)
- **Purpose**: Cross-repository coordination and documentation

### Working with Components
- Each subdirectory is an independent Git repository
- Use the appropriate repository's CLAUDE.md for component-specific work
- For ecosystem-wide changes, coordinate through this repository

## Key Workflows

### Student Repository Creation
```bash
# Create student thesis repository (automated)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/thesis-management-tools/v1/create-repo/setup.sh)" bash thesis

# Create weekly report repository
STUDENT_ID=k21rs001 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/thesis-management-tools/v1/create-repo/setup.sh)" bash wr
```

### Student Progress Monitoring
```bash
# Monitor all students' thesis progress
thesis-monitor status

# Show only protection status
thesis-monitor status --show-protection

# Verbose output
thesis-monitor status --verbose
```

### For Ecosystem-level Changes
1. Work in this management repository
2. Update ECOSYSTEM.md for architectural changes
3. Use ecosystem_manager/ecosystem-manager for coordination

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

- **[Architecture Guide](docs/CLAUDE-ARCHITECTURE.md)** - Ecosystem structure, dependencies, repository boundaries
- **[Workflows & Examples](docs/CLAUDE-WORKFLOWS.md)** - Detailed command examples, cross-repository coordination

## Development Notes

- **ai-reviewer**: Fork maintained here due to upstream bugs
- **ai-academic-paper-reviewer**: Developed based on `ai-reviewer`.
- **thesis-monitor**: Elixir-based monitoring tool with CSV integration (own repository: smkwlab/thesis-monitor)
- **Cross-repository Coordination**: All repositories work together as unified system