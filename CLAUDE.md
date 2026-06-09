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
- **thesis-student-registry/**: Secure student repository registry and monitoring tools
- **latex-ecosystem/**: This management repository for ecosystem coordination

### GitHub Actions
- **ai-reviewer/**: Automated PR review action (bug-fixed fork)
- **ai-academic-paper-reviewer/**: Academic paper review action
- **latex-release-action/**: PDF generation and release automation

## Important Conventions

### This Management Repository
- **Tracks**: ECOSYSTEM.md, ecosystem-manager.sh, README.md, CLAUDE.md, .claude/, docs/
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
3. Use ecosystem-manager.sh for coordination

### For Component-specific Changes
1. Navigate to the specific repository directory
2. Use that repository's CLAUDE.md for context
3. Follow that repository's development workflow

### Updating Workflow Files in Student Repositories

**IMPORTANT**: Student repositories use draft-to-draft PR workflow (`2nd-draft` → `1st-draft` → `0th-draft` → `main`). When updating workflow files, you must propagate changes through the branch hierarchy to avoid triggering GitHub Actions security restrictions.

#### Why This Matters

- `pull_request` event workflows use the **base branch's** workflow file
- If workflow changes appear in PR diffs, GitHub may skip workflow execution for security
- Each draft branch needs the updated workflow for proper PR handling

#### Correct Procedure (Automated)

Use the `propagate-workflow` command of `registry-manager`, the Elixir escript
located in the `registry_manager/` directory of the `thesis-student-registry`
repository.

> **Prerequisite**: All commands below are run from the `thesis-student-registry`
> checkout root. Build the escript first (also from that root):
> ```bash
> (cd registry_manager && mix escript.build)
> ```
> Without this build step the `./registry_manager/registry-manager` binary does
> not exist yet, so the command fails (the exact wording varies by shell/OS, e.g.
> "No such file or directory").

```bash
# (run from the thesis-student-registry checkout root)

# Check what would be done (dry-run)
./registry_manager/registry-manager propagate-workflow k22rs001-sotsuron --dry-run

# Propagate workflow updates for a single repository
./registry_manager/registry-manager propagate-workflow k22rs001-sotsuron

# Propagate to all thesis repositories at once
./registry_manager/registry-manager propagate-workflow --all --type thesis

# Check all repositories first
./registry_manager/registry-manager propagate-workflow --all --type thesis --dry-run
```

#### Manual Procedure (if needed)

```bash
# 1. Update main branch first
git checkout main
# Make workflow changes
git add .github/workflows/
git commit -m "Update workflow files"
git push

# 2. Propagate to each draft branch via merge (preserves commit history)
git checkout 0th-draft
git merge main -m "Merge workflow updates from main"
git push

git checkout 1st-draft
git merge 0th-draft -m "Merge workflow updates from 0th-draft"
git push

git checkout 2nd-draft
git merge 1st-draft -m "Merge workflow updates from 1st-draft"
git push

# Continue for 3rd-draft, etc. if they exist
```

#### What NOT To Do

❌ **Do not push identical changes independently to each branch**:
```bash
# WRONG - creates separate commit histories
git checkout 0th-draft && git add . && git commit && git push
git checkout 1st-draft && git add . && git commit && git push
git checkout 2nd-draft && git add . && git commit && git push
```

This causes:
- PR diffs to include workflow file changes (even if content is identical)
- GitHub Actions security restrictions to skip `pull_request` triggered workflows
- Notification emails and other PR-triggered actions to fail

#### Verification

After updating, verify that existing PRs don't show workflow file changes:
```bash
gh pr diff <PR_NUMBER> --repo smkwlab/<repo> | grep -E "\.github/workflows"
# Should return empty if done correctly
```

## Security & Data Management

- **Student Data Separation**: `thesis-student-registry` repository keeps student information separate for security
- **Automated Registry Updates**: GitHub Actions automatically update student repository lists
- **Branch Protection**: Automatic setup for PR-based review workflows
- **Access Control**: Fine-grained permissions for different user roles

## Detailed Documentation

- **[Architecture Guide](docs/CLAUDE-ARCHITECTURE.md)** - Ecosystem structure, dependencies, repository boundaries
- **[Workflows & Examples](docs/CLAUDE-WORKFLOWS.md)** - Detailed command examples, cross-repository coordination

## Development Notes

- **ai-reviewer**: Fork maintained here due to upstream bugs
- **ai-academic-paper-reviewer**: Developed based on `ai-reviewer`.
- **thesis-monitor**: Elixir-based monitoring tool with CSV integration
- **Cross-repository Coordination**: All repositories work together as unified system