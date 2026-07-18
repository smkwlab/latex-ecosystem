# Management Repository Guide

This document describes the **latex-ecosystem management repository itself** — its
Git boundaries, directory structure, and the principles that govern what it
tracks.

For the **ecosystem-wide architecture** — all component repositories, the
dependency matrix, version compatibility, and update chains — see
[../ECOSYSTEM.md](../ECOSYSTEM.md).

## What this repository is

`latex-ecosystem` is the coordination hub for the LaTeX thesis environment. It
does **not** contain the components themselves — each is an independent Git
repository — but it tracks ecosystem-level coordination material (the overview
and documentation) and provides a workspace where the component repositories,
including the `ecosystem-manager` tool, are cloned side by side.

## Git Repository Boundaries

### Management Repository Structure

```
latex-ecosystem/                 # This management repository
├── .git/                       # Git for management files only
├── ECOSYSTEM.md                # Tracked - ecosystem overview
├── README.md                   # Tracked - repository overview
├── setup.sh                    # Tracked - ecosystem setup script
├── CLAUDE.md                   # Tracked - management-repo instructions
├── .claude/                    # Tracked - claude configuration
├── docs/                       # Tracked - ecosystem documentation
│   ├── MANAGEMENT-REPOSITORY.md   # This file
│   ├── MANAGEMENT-WORKFLOWS.md    # Management workflow examples
│   └── ...                        # Other guides (setup, git, multi-org, review)
│
├── ecosystem-manager/          # Independent repository (cloned alongside; Elixir escript coordination tool)
│   ├── .git/                  # Separate Git repository
│   └── ...
│
├── latex-environment/          # Independent repository (cloned alongside)
│   ├── .git/                  # Separate Git repository
│   ├── CLAUDE.md              # Different CLAUDE.md for that repo
│   └── docs/                  # Component-specific documentation
│
├── sotsuron-template/          # Independent repository (cloned alongside)
│   ├── .git/                  # Separate Git repository
│   └── ...
│
└── (other independent repos...)
```

The component repositories (`latex-environment`, `sotsuron-template`, …) are
listed and categorized in
[../ECOSYSTEM.md](../ECOSYSTEM.md#repository-overview); this repository does not
track their content.

## Design Principles

### Management Repository Principles
- **Tracks files only**: No subdirectory content except `docs/`
- **Coordination focus**: Cross-repository coordination and documentation
- **Independent components**: Each subdirectory is a separate Git repository
- **Exception for docs/**: Ecosystem-wide documentation is centrally managed here
- **Documentation placement**: Reader-facing documentation (students, faculty,
  operators) lives in this repository's `docs/`. A component repository's own
  `docs/` is developer-facing only (`CLAUDE-*.md` and similar); its
  reader-facing entry points are its top-level files (README,
  WRITING-GUIDE.md, …)

### Working across the component repositories
- Each subdirectory is an independent Git repository with its own history,
  `CLAUDE.md`, and release cycle.
- Always confirm which repository you are in (`pwd` / `git status`) before Git
  operations — see [MANAGEMENT-WORKFLOWS.md](MANAGEMENT-WORKFLOWS.md).
- For ecosystem-wide changes, coordinate through this repository and keep
  [../ECOSYSTEM.md](../ECOSYSTEM.md) up to date.
