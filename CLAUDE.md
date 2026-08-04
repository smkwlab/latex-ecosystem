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
./ecosystem-manager/ecosystem-manager list

# Detailed status: branch, uncommitted changes, last commit, PRs, issues
./ecosystem-manager/ecosystem-manager list --long

# Fast status without GitHub API calls
./ecosystem-manager/ecosystem-manager list --fast

# Show only repositories with urgent issues / open PRs / PRs needing review
./ecosystem-manager/ecosystem-manager list --urgent-issues
./ecosystem-manager/ecosystem-manager list --with-prs
./ecosystem-manager/ecosystem-manager list --needs-review

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

**IMPORTANT**: Student repositories use the draft PR cycle (branch hierarchy `2nd-draft` → `1st-draft` → `0th-draft` → `main`; terminology map in docs/GLOSSARY.md). Workflow changes must be propagated through the branch hierarchy via merge — pushing identical changes independently to each branch makes workflow diffs appear in PRs, which triggers GitHub Actions security restrictions and skips `pull_request` workflows.

Use the **`/propagate` skill** ([.claude/skills/propagate/SKILL.md](.claude/skills/propagate/SKILL.md)) for the full procedure: registry-manager setup check → dry-run → `propagate-workflow` execution → PR diff verification, including the manual merge-chain fallback.

### 依存管理基盤（Renovate 一本化）

Dependency updates for the development infrastructure repositories and the document templates are handled by Renovate; Dependabot is not used. Shared presets live in `smkwlab/.github` and are referenced through the moving `v1` tag.

The governing principle is that **Renovate checks and Renovate merges** — GitHub's auto-merge releases a merge as soon as branch protection is satisfied, which on a repository with no required status checks means before CI has run. Renovate waits for every check run on the PR instead, so the decision does not depend on repository settings. Branch protection is the floor for human merges, not the condition for automated ones.

Auto-merge covers grouped minor/patch/digest updates; major updates always get individual review. Automated merges reach `main` only — publishing a Docker image tag, moving `v1`, and cutting a release stay manual.

Student repositories have no Renovate, so they must reach infrastructure through a shared workflow rather than referencing it directly: a pin nobody can bump never moves again, and the reference still resolves, so nothing fails to signal it. Templates carry the same constraint because their contents are copied into every repository generated from them, which is why they use the `:template` preset instead of `:latex` and keep the shared-workflow reference unpinned.

See [docs/DEPENDENCY-MANAGEMENT.md](docs/DEPENDENCY-MANAGEMENT.md) for the preset layout, reference modes, per-repository required status checks, and the invariants to preserve when changing any of it.

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
- **[Dependency Management](docs/DEPENDENCY-MANAGEMENT.md)** - Renovate presets, auto-merge policy, required status checks

## Development Notes

- **ai-academic-paper-reviewer**: Developed based on `ai-reviewer`; now the single AI reviewer (ACADEMIC/CODE modes)
- **ai-reviewer** (legacy): superseded by ai-academic-paper-reviewer, no longer used by migrated workflows; kept for reference only
- **thesis-monitor**: Elixir-based monitoring tool with CSV integration (own repository: smkwlab/thesis-monitor)
- **Cross-repository Coordination**: All repositories work together as unified system