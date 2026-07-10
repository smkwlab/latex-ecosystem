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
     (initialize with `registry-manager init`). A non-standard name requires
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

## Shared infrastructure decisions

Two pieces of infrastructure are referenced literally from every template and
need an explicit policy per deployment (discussion in
[#105](https://github.com/smkwlab/latex-ecosystem/issues/105)):

- **`smkwlab/.github` reusable workflows** — all template workflows use
  `uses: smkwlab/.github/.github/workflows/<name>.yml@v1` (draft-chain
  automation, ML notification, AI review, LaTeX build). Options:
  - *Shared use*: keep referencing `smkwlab/.github` (requires it to stay
    public; org-specific values such as notification targets must be
    externalized).
  - *Fork*: copy `.github` into the new org and rewrite every `uses:` line
    in every template.
- **`ghcr.io/smkwlab/texlive-ja-textlint`** — the DevContainer image
  referenced by `latex-environment/.devcontainer/devcontainer.json` and the
  build workflows. Public pulls work as-is; forking the image pipeline is only
  needed if the org wants independent image maintenance.

## Local tool configuration

Faculty machines in the new org need per-tool configuration. **Do not rely on
defaults**: until the issues above are fixed, both Elixir tools default to
`github_org: "smkwlab"` and will silently operate on smkwlab data.

- **registry-manager**: `~/.config/registry-manager/config.yml`

  ```yaml
  github_org: your-org
  registry_repo: your-org/thesis-student-registry   # explicit; required for writes
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
3. File a repository-creation issue via the automation flow and confirm:
   the repository is created in the new org, branch protection is applied,
   and `data/registry.json` in the new org's registry gains the entry.
4. Open a draft PR in a created student repository and confirm the template
   workflows (build, draft-chain, review) run without referencing missing
   secrets or private `smkwlab` resources.
