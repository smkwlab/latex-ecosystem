# Multi-Org Deployment Guide

How to deploy the LaTeX thesis ecosystem to a GitHub organization other than
`smkwlab`. Based on the cross-repository audit of 2026-07-10
([#105](https://github.com/smkwlab/latex-ecosystem/issues/105)).

**Status**: The automation core is already organization-scoped, but several
entry points still hardcode `smkwlab`. This guide documents what works today,
what must be prepared in the new organization, and which known blockers must
be resolved (tracked as issues) before a deployment is fully functional.

## Architecture: how the org ↔ registry relationship is resolved

The org/registry relationship is **not** stored in any central configuration.
It is resolved per component, at three different layers:

1. **GitHub Actions (automation core)** — derived dynamically from
   `github.repository_owner`. The registry repository defaults to the
   convention `<org>/thesis-student-registry` and can be overridden with the
   org/repo variable `REGISTRY_REPO`
   (`thesis-management-tools/.github/workflows/student-repo-management.yml`).
   No local configuration is involved.
2. **Local management tools** — resolved from per-tool config files
   (`~/.config/<tool>/config.yml`) with the same convention defaults. See
   [Local tool configuration](#local-tool-configuration).
3. **Student-facing entry points** (`setup.sh`, `aldc`, template workflows) —
   currently hardcoded to `smkwlab`. These are the actual blockers; see
   [Known blockers](#known-blockers).

## What works out of the box

These components follow the *Organization-Scoped Deployment* principle
(ECOSYSTEM.md) and need no code changes:

- **Repository creation pipeline** (`thesis-management-tools`):
  `student-repo-management.yml`, `process-pending-issues.sh`, and
  `setup-branch-protection.sh` derive the organization from
  `github.repository_owner` / `GITHUB_REPOSITORY` and resolve the registry as
  `<org>/thesis-student-registry`. Cross-org requests are rejected by an
  explicit guard.
- **Registry auto-registration**: `data/registry.json` updates go through the
  GitHub API using the resolved registry repository. Authentication uses a
  GitHub App installation token minted per run — no PAT.
- **ecosystem_manager**: fully org-agnostic. The organization is derived from
  the `origin` remote of the workspace root; repository auto-discovery filters
  by that owner.

## Prerequisites in the new organization

Create these before running any automation:

1. **Repositories**
   - `thesis-student-registry` containing `data/registry.json`
     (initialize with `registry-manager init --org your-org`; see
     [Local tool configuration](#local-tool-configuration)). A non-standard name requires
     setting the `REGISTRY_REPO` org/repo variable on
     `thesis-management-tools`.
   - Forks/copies of `thesis-management-tools` and the templates the org will
     use: `sotsuron-template`, `ise-report-template`, `wr-template`
     (these are resolved as `<org>/<template>` and must exist in the org).
2. **GitHub App**
   - Create and install a GitHub App in the org with **contents: write**,
     **administration: write**, and **issues: write** on
     `thesis-management-tools`, `thesis-student-registry`, and the student
     repositories (org-wide installation is simplest).
   - Set `APP_ID` and `APP_PRIVATE_KEY` secrets on
     `thesis-management-tools`.
3. **Secrets for optional workflows**
   - `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` (AI review / Claude Q&A jobs in
     the templates fail without them).
   - Mailing-list notification secrets consumed by the
     `notify-ml-on-pr` reusable workflow (`secrets: inherit`).

## Known blockers

Tracked issues that must be resolved (or worked around by editing forks)
before student-facing flows work in another org:

| Component | Problem | Issue |
|---|---|---|
| `setup.sh` (student entry point) | Org membership check, `TARGET_ORG` guard, and tools clone URL are hardcoded to `smkwlab`; repository creation in another org is effectively blocked | [thesis-management-tools#498](https://github.com/smkwlab/thesis-management-tools/issues/498) |
| `create-repo` collateral | `latex`/`poster` templates pinned to `smkwlab`, aldc download URL, auto-assign reviewer pinned to a personal account | [thesis-management-tools#499](https://github.com/smkwlab/thesis-management-tools/issues/499) |
| `aldc` installer | `REPOSITORY_OWNER='smkwlab'` with no override; always installs `smkwlab/latex-environment` | [aldc#32](https://github.com/smkwlab/aldc/issues/32) |
| `thesis-monitor` defaults | Default `github_org: "smkwlab"` silently reads the smkwlab registry when run without config | [thesis-monitor#28](https://github.com/smkwlab/thesis-monitor/issues/28) |
| `registry-manager` defaults | Default `github_org: "smkwlab"` can silently target smkwlab student repos; `init` embeds smkwlab links | [registry-manager#45](https://github.com/smkwlab/registry-manager/issues/45) |
| `thesis-repo-manager.sh` | Fully hardcoded (~20 call sites); unusable outside smkwlab (manual tool, low priority) | [thesis-management-tools#500](https://github.com/smkwlab/thesis-management-tools/issues/500) |

## Shared infrastructure: reference strategy

Some infrastructure is referenced *literally* (with `smkwlab/` in the string)
from every template, and — unlike deployment identity — this **cannot** be made
dynamic: a GitHub Actions `uses:`/`container:` reference may not contain an
expression, so `${{ github.repository_owner }}` is not resolvable there. A
workflow therefore cannot point at "my own org's" copy of a reusable workflow
or action; the org is fixed at the moment the string is written.

**Decision (#105): treat this as public shared infrastructure.** The following
are published as public shared services; any organization consumes them by
referencing `smkwlab/...` directly, and injects its own values through Actions
secrets and variables rather than editing the shared code:

| Shared service | Referenced by | Per-org input |
|---|---|---|
| `smkwlab/.github` reusable workflows (`.github/workflows/<name>.yml@v1`) | template caller workflows (draft-chain, ML notify, AI review, LaTeX build, QA) | secrets / `secrets: inherit` |
| `smkwlab/latex-release-action@v3` | `latex-build` / `latex-build-modified` reusables | — |
| `smkwlab/ai-academic-paper-reviewer@v1` | `ai-review` reusable | `ANTHROPIC_API_KEY` / `GEMINI_API_KEY` |
| `ghcr.io/smkwlab/texlive-ja-textlint` | `devcontainer.json`, build workflows | — |

Why shared use is the default, not fork:

- The reusable **bodies** are already org-agnostic — org derivation uses
  `github.repository_owner`, and org-specific values (mailing-list address,
  SMTP, API keys) are consumed through secrets, not hardcoded. Only the
  *addresses* above carry `smkwlab`.
- Because `uses:` cannot be templated, forking means rewriting every caller in
  every template (7 workflows × 5 templates) and re-syncing them on every
  upstream change. That cost buys independence but nothing else for a
  deployment that trusts the shared services.

**Accepted trade-offs.** Shared use means a permanent dependency on the
`smkwlab` org staying public, and template PRs in another org execute
smkwlab-owned reusable code with that org's secrets (the normal trust model for
any public reusable workflow). An org that needs to sever the dependency — for
independence, air-gapping, or per-org customization of the reusable logic
itself — should fork instead; see [When to fork](#when-to-fork).

**Hardening follow-up (not org-specific).** The legacy `ai-reviewer.yml`
reusable pins `toshi0806/ai-reviewer` — a *personal account*, not even an org —
which is a single point of failure independent of multi-org concerns. The
current path is `ai-review.yml` (→ `smkwlab/ai-academic-paper-reviewer`);
`ai-reviewer.yml` should be retired or repointed to an org-owned action.

### When to fork

Choose the fork path only when shared use is unacceptable (independence
requirement, or you need to change the reusable logic per org). Then:

- Copy `smkwlab/.github`, `latex-release-action`, `ai-academic-paper-reviewer`,
  and the image pipeline into the org, and rewrite `uses:`/`container:`
  references to the org.
- Note the two distribution-side seams that assume `smkwlab`: the caller
  templates in `smkwlab/.github/scripts/callers/*.yml` hardcode the
  `smkwlab/.github` owner (only the `@__REF__` version is tokenized), and
  `scripts/distribute-workflow.sh` defaults `ORG="smkwlab"` with no `--org`
  flag. Both need org parameterization for a fork workflow to be maintainable.

## Local tool configuration

Faculty machines in the new org need per-tool configuration. **Do not rely on
defaults**: until the issues above are fixed, both Elixir tools default to
`github_org: "smkwlab"` and will silently operate on smkwlab data.

- **registry-manager**: `~/.config/registry-manager/config.yml`

  ```yaml
  github_org: your-org
  registry_repo: your-org/thesis-student-registry   # explicit; required for all registry operations
  ```

  Or generate it with `registry-manager init --org your-org`.
- **thesis-monitor**: run `thesis-monitor init --org your-org` (the `--org`
  flag works **only** on `init`; runtime commands read the config file).
- **Student roster (optional)**: place the CSV at
  `~/.config/<your-org>/students.csv` — the convention path follows
  `github_org` automatically.
- **ecosystem_manager**: no org setting needed; configure workspace paths in
  `~/.config/ecosystem-manager/config.exs` if you use multiple workspaces.

## Verification checklist

After preparing the org and configuration:

1. `registry-manager list` reads the new org's registry (not smkwlab's).
2. `thesis-monitor status` reports repositories of the new org only.
3. File a repository-creation request issue on the org's
   `thesis-management-tools` fork — normally submitted by students via
   `setup.sh`; until
   [thesis-management-tools#498](https://github.com/smkwlab/thesis-management-tools/issues/498)
   is resolved, create the issue manually in the format expected by
   `process-pending-issues.sh` — and confirm:
   the repository is created in the new org, branch protection is applied,
   and `data/registry.json` in the new org's registry gains the entry.
4. Open a draft PR in a created student repository and confirm the template
   workflows (build, draft-chain, review) run without referencing missing
   secrets or private `smkwlab` resources.
