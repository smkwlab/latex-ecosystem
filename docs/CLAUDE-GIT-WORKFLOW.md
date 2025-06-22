# Git Workflow Best Practices

This document covers Git workflow best practices learned from actual development experiences in the LaTeX ecosystem.

## Critical Lesson: Avoid Main Branch Conflicts (2025-06-22)

**Problem Scenario**: During thesis-management-tools development, local main branch diverged from remote main, causing merge conflicts when PR #75 was merged.

**Root Cause Analysis**:
```bash
# What went wrong
git status
# → Your branch and 'origin/main' have diverged,
#   and have 9 and 1 different commits each, respectively.

# Local main had 9 commits that weren't in remote
# Remote main had 1 new commit (PR #75 merge)
# → Automatic merge conflict in setup-branch-protection.sh
```

**Why This Happened**:
- Multiple changes were committed directly to local main branch
- Feature work was not isolated in feature branches
- Local main was not kept in sync with remote main
- PR work was mixed with direct commits

## Correct Git Workflow

**❌ Problem Workflow (what caused conflicts)**:
```bash
# Direct commits to main (AVOID THIS)
git checkout main
git add . && git commit -m "Add feature X"
git add . && git commit -m "Fix bug Y"
# ... multiple direct commits ...
# Later: PR #75 gets merged remotely
git pull origin main  # → CONFLICT!
```

**✅ Correct Workflow**:
```bash
# 1. Always start with clean, updated main
git checkout main
git pull origin main

# 2. Create feature branch for ALL changes
git checkout -b feature/descriptive-name

# 3. Work on feature branch
git add . && git commit -m "Implement feature X"
git add . && git commit -m "Add tests for feature X"

# 4. Push feature branch and create PR
git push -u origin feature/descriptive-name
gh pr create --title "Add feature X" --body "Description..."

# 5. After PR is merged, update local main
git checkout main
git pull origin main
git branch -d feature/descriptive-name  # Clean up
```

## Branch Strategy Rules

**For Component Repositories**:
1. **Never commit directly to main branch**
2. **Always use feature branches** for any change
3. **Keep feature branches focused** on single features/fixes
4. **Regularly sync main branch** with remote before creating new features
5. **Use PRs for all changes** to maintain review process

**Branch Naming Convention**:
```bash
feature/add-student-id-normalization
fix/github-actions-bash-rematch
enhance/error-handling-improvements
docs/update-architecture-guide
```

## Recovery from Conflicts

**When conflicts occur** (emergency procedure):
```bash
# 1. Assess the situation
git status
git log --oneline -n 10

# 2. If safe to reset (no important unpushed work)
git fetch origin
git reset --hard origin/main

# 3. If local changes need to be preserved
git stash push -m "WIP: local changes before sync"
git pull origin main
git stash pop  # Resolve conflicts manually if needed

# 4. Create feature branch for any new work
git checkout -b feature/continue-work
```

## Prevention Strategies

**Daily Workflow**:
```bash
# Start of day: sync main
git checkout main && git pull origin main

# Before new work: create feature branch
git checkout -b feature/today-work

# End of day: push feature branch
git push -u origin feature/today-work
```

**Pre-PR Checklist**:
- [ ] Feature branch is up to date with main
- [ ] All commits are focused and well-described
- [ ] Tests pass locally
- [ ] No merge conflicts with main

## Emergency Procedures

**If main branch becomes corrupted**:
```bash
# Reset local main to match remote
git checkout main
git fetch origin
git reset --hard origin/main

# Recreate feature work from backup/stash
git checkout -b feature/recovered-work
# Apply changes...
```

This workflow prevents the merge conflicts experienced in PR #75 and ensures smooth collaboration across the ecosystem.

## Integration with Ecosystem Workflows

### For Ecosystem Management Repository
- Apply same branch strategy rules
- Use feature branches for ecosystem-wide documentation updates
- Coordinate changes across multiple component repositories

### For Component Repositories
- Follow same workflow for component-specific changes
- Ensure coordination with ecosystem management repository
- Test changes against ecosystem compatibility