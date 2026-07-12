# Getting Started with Ecosystem Operations

A step-by-step guide for taking over (or newly starting) the operation of the
LaTeX thesis ecosystem. Details live in the linked documents — this guide only
tells you which steps to take and in what order.

## 1. Who this is for

You are about to **operate** this ecosystem: creating student repositories,
running the PR-based review flow, and managing the student registry. If you
only want to *write* a thesis or *review* one, see the
[documentation guide](README.md) instead.

## 2. Prerequisites

- **Admin access** to the target GitHub organization
- **GitHub CLI (`gh`)**, authenticated (`gh auth login`)
- **Docker** (student repository creation runs in a container)
- **Elixir/Mix** — only if you build the developer workspace or use
  `ecosystem-manager` / `registry-manager` / `thesis-monitor`

Tool installation details: see the Prerequisites section of
[SETUP-AND-RELEASE.md](SETUP-AND-RELEASE.md#prerequisites).

## 3. Path A: join the existing deployment (smkwlab)

The `smkwlab` organization is already provisioned; you only need a local
workspace.

```bash
# One-line workspace setup (clones all component repositories)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/latex-ecosystem/main/setup.sh)"

# Build the ecosystem manager (once)
cd latex-ecosystem-dev   # default directory created by setup.sh (skipped when run inside an existing checkout)
(cd ecosystem_manager && mix escript.build)

# Verify: status of every repository
./ecosystem_manager/ecosystem-manager status
```

Setup variants (custom location, manual clone) are described in
[SETUP-AND-RELEASE.md](SETUP-AND-RELEASE.md#quick-setup).

Continue with [First student repository](#5-first-student-repository).

## 4. Path B: deploy to a new organization

A new organization must provision, in essence:

- one **GitHub App** (repository automation credentials),
- one private **registry repository** (`<org>/thesis-student-registry`),
- the **document templates** copied into the org, and
- a small set of **secrets and variables**.

Everything — exact permissions, secrets tables, fork configuration, and the
verification checklist — is in
[MULTI-ORG-DEPLOYMENT.md](MULTI-ORG-DEPLOYMENT.md). Follow it end to end, then
come back here.

## 5. First student repository

Two ways to create one:

1. **Student-driven (normal path)** — have the student run the one-liner from
   [student-repo-management/create-repo/setup.sh](https://github.com/smkwlab/student-repo-management/blob/main/create-repo/setup.sh):

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/smkwlab/student-repo-management/main/create-repo/setup.sh)" bash thesis
   ```

2. **Via registration issue** — file the repository-creation request issue on
   the org's `student-repo-management`; GitHub Actions does the rest.

After creation, verify:

- **Branch protection** was applied to the new repository
- The repository was registered in `data/registry.json`:

  ```bash
  ./thesis-monitor/thesis-monitor status
  ```

If either check fails, see the automation setup guide:
[GITHUB-ACTIONS-SETUP.md](https://github.com/smkwlab/student-repo-management/blob/main/docs/GITHUB-ACTIONS-SETUP.md).

## 6. Onboard your faculty and students

- **Faculty** →
  [TEACHER-ONBOARDING.md](TEACHER-ONBOARDING.md)
- **Students** → the README generated in each student repository, and
  [STUDENT-WORKFLOW.md](STUDENT-WORKFLOW.md)

## 7. Day-2 operations

- **Routine management** (status checks, cross-repository coordination,
  releases) → [MANAGEMENT-WORKFLOWS.md](MANAGEMENT-WORKFLOWS.md) and
  [SETUP-AND-RELEASE.md](SETUP-AND-RELEASE.md)
- **Student progress monitoring** →
  [thesis-monitor](https://github.com/smkwlab/thesis-monitor)
  (`thesis-monitor status`)
- **Review rules of record** →
  [PR-REVIEW-GUIDELINES.md](PR-REVIEW-GUIDELINES.md)
