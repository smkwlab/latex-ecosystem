# Multi-Org Deployment Guide

How to deploy the LaTeX thesis ecosystem to a GitHub organization other than
`smkwlab`. Based on the cross-repository audit of 2026-07-10
([#105](https://github.com/smkwlab/latex-ecosystem/issues/105)).

**Status**: The automation core is organization-scoped, and the student-facing
entry points that used to hardcode `smkwlab` are now parameterized with
`smkwlab` defaults (see [Resolved blockers](#resolved-blockers)). This guide
documents what a new organization must provision, the exact resources and
secrets the automation consumes, and the one remaining low-priority blocker.

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
   parameterized through environment knobs that default to `smkwlab`
   (`DEFAULT_ORG`, `TEMPLATE_REPO`, `ALDC_URL`, …); a fork sets these to rehome
   itself (see [create-repo fork configuration](#5-create-repo-fork-configuration)).
   The template workflows still reference `smkwlab/.github` literally by design
   (see [Shared infrastructure](#shared-infrastructure-reference-strategy)).

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

The automation is driven by one GitHub App, one registry repository, a set of
templates, and a small set of secrets and variables. Provision all of the
following before onboarding students. (Verified against
`student-repo-management.yml`, `ai-code-review.yml`, `notify-ml-on-pr.yml`, and
`create-repo/*.sh`.)

### 1. Repositories

| Repository | Purpose | Notes |
|---|---|---|
| `<org>/thesis-student-registry` (private) | Holds `data/registry.json` | Initialize with `registry-manager init --org <org>` (see [Local tool configuration](#local-tool-configuration)). A non-standard name requires the `REGISTRY_REPO` variable below. |
| `<org>/thesis-management-tools` | Hosts the registration workflow and `create-repo` scripts | Fork/copy. Carries the App secrets and the fork configuration below. |
| `<org>/sotsuron-template`, `<org>/wr-template`, `<org>/ise-report-template` | Student document templates | **Must exist in the org** — `create-repo` resolves them as `${ORGANIZATION}/<template>`. |
| `<org>/latex-template`, `<org>/poster-template` | General LaTeX / poster templates | Default to `smkwlab/...` (shared). Only needed in the org if you point `TEMPLATE_REPO` at your own copy. |

### 2. GitHub App (on `<org>/thesis-management-tools`)

`student-repo-management.yml` mints a per-run installation token with
`actions/create-github-app-token` using `owner: <org>`, so a single App reaches
this repo, the registry, and the student repositories.

- **Permissions**: `contents: write` (registry commits and repo content),
  `administration: write` (branch protection), `issues: write` (close
  registration issues).
- **Installation**: org-wide is simplest (must cover `thesis-management-tools`,
  the registry, and the student repositories).
- **Secrets on `thesis-management-tools`**: `APP_ID`, `APP_PRIVATE_KEY`.

### 3. Actions variable (optional)

- `REGISTRY_REPO` on `thesis-management-tools` — set only when the registry
  repository name deviates from `<org>/thesis-student-registry`.

### 4. Secrets

Place each where its workflow runs. Prefer **organization secrets** for the AI
keys and the ML settings so every student repository inherits them.

| Secret(s) | Consumed by | Where | Required? |
|---|---|---|---|
| `APP_ID`, `APP_PRIVATE_KEY` | Registration automation (`student-repo-management.yml`) | `thesis-management-tools` | **Yes** — registration cannot run without them |
| `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` | `ai-review` / `claude-qa` in student repos, and TMT's own `ai-code-review.yml` | Org (student repos) + `thesis-management-tools` | Optional — the AI jobs skip cleanly when absent |
| `SMTP_SERVER`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_FROM`, `LAB_ML_ADDRESS` | `notify-ml-on-pr` reusable (sotsuron / ise / latex templates, `secrets: inherit`) | Org | Required by that workflow — **all six**. To skip ML mail, delete `notify-ml-on-pr.yml` from the templates instead. |

All secret values are plain strings (GitHub secrets are always strings). Set
`SMTP_PORT` to e.g. `587`; `notify-ml-on-pr` passes it to the mail action as-is,
so no numeric type is needed.

### 5. create-repo fork configuration

The forked `create-repo` scripts default every org-specific value to `smkwlab`
(env vars read by `setup.sh` / `common-lib.sh`; introduced in
[thesis-management-tools#498](https://github.com/smkwlab/thesis-management-tools/issues/498)
and [#499](https://github.com/smkwlab/thesis-management-tools/issues/499)). A
new org overrides:

| Variable | Default | Set to |
|---|---|---|
| `DEFAULT_ORG` | `smkwlab` | your org (drives the membership check, target org, and tools owner) |
| `TOOLS_REPO_OWNER` / `TOOLS_REPO_NAME` / `TOOLS_CLONE_URL` | `<DEFAULT_ORG>` / `thesis-management-tools` / derived | your fork's location |
| `TEMPLATE_REPO` | `smkwlab/latex-template`, `smkwlab/poster-template` | your copy (latex/poster only; thesis/wr/ise derive from the org) |
| `ALDC_URL` | `…/smkwlab/aldc/main/aldc` | your aldc copy (or keep the shared one) |
| `AUTO_ASSIGN_REVIEWER` | `toshi0806` | your reviewer account (empty disables auto-assign) |
| `SETUP_GIT_EMAIL_DOMAIN` | `smkwlab.github.io` | your domain |

## Resolved blockers

The `smkwlab` hardcodes that used to block other-org deployment are fixed. Each
is now parameterized with a `smkwlab` default, so smkwlab behaviour is
unchanged; a fork sets the knobs in
[create-repo fork configuration](#5-create-repo-fork-configuration) and the
[local tool configuration](#local-tool-configuration).

| Component | What changed | Issue |
|---|---|---|
| `setup.sh` (student entry point) | Membership check, target-org guard, and tools clone URL are `DEFAULT_ORG` / `TOOLS_*` overridable | [thesis-management-tools#498](https://github.com/smkwlab/thesis-management-tools/issues/498) ✅ |
| `create-repo` collateral | `TEMPLATE_REPO` (latex/poster), `ALDC_URL`, `AUTO_ASSIGN_REVIEWER`, `SETUP_GIT_EMAIL_DOMAIN` overrides | [thesis-management-tools#499](https://github.com/smkwlab/thesis-management-tools/issues/499) ✅ |
| `aldc` installer | `ALDC_REPOSITORY_OWNER` / `ALDC_REPOSITORY_NAME` env override | [aldc#32](https://github.com/smkwlab/aldc/issues/32) ✅ |
| `thesis-monitor` defaults | Default `github_org` dropped; derived from `registry_repo` owner, otherwise an explicit error | [thesis-monitor#28](https://github.com/smkwlab/thesis-monitor/issues/28) ✅ |
| `registry-manager` defaults | Default `github_org` dropped; derived from `registry_repo` owner, otherwise an explicit error | [registry-manager#45](https://github.com/smkwlab/registry-manager/issues/45) ✅ |

## Remaining blocker

| Component | Problem | Issue |
|---|---|---|
| `thesis-repo-manager.sh` | Fully hardcoded (~20 call sites); unusable outside smkwlab. Manual tool, low priority — deprecation is an option | [thesis-management-tools#500](https://github.com/smkwlab/thesis-management-tools/issues/500) |

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

**Out of scope — the legacy `ai-reviewer.yml` reusable.** `smkwlab/.github`
also ships a legacy `ai-reviewer.yml` reusable that pins `toshi0806/ai-reviewer`
(a personal account). It is **not part of the deployment path**: no template
(`sotsuron` / `wr` / `ise-report` / `sotsuron-report` / `latex` / `poster`)
references it, and `scripts/callers/` ships no caller for it, so newly-created
repositories and new-org deployments never pick it up — the current AI-review
path is `ai-review.yml` (→ `smkwlab/ai-academic-paper-reviewer`). Only
pre-existing repos that still call it are affected. Retiring it (or repointing
to an org-owned action) is therefore a smkwlab-internal cleanup item for those
legacy repos, not a multi-org concern.

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

1. With the org configured (see
   [Local tool configuration](#local-tool-configuration)), `registry-manager
   list` reads the new org's registry — and with no config it now errors
   explicitly instead of falling back to smkwlab.
2. `thesis-monitor status` reports repositories of the new org only (same
   explicit-error-without-config guarantee).
3. Have a student run `setup.sh` from the fork (configured per
   [create-repo fork configuration](#5-create-repo-fork-configuration)), or file
   the repository-creation request issue on the org's `thesis-management-tools`
   directly, and confirm: the repository is created in the new org, branch
   protection is applied, and `data/registry.json` in the new org's registry
   gains the entry.
4. Open a draft PR in a created student repository and confirm the template
   workflows (build, draft-chain, review) run without referencing missing
   secrets or private `smkwlab` resources.
