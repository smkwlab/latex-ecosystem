# LaTeX Thesis Environment Ecosystem

This document describes the architecture and management strategy for the thesis-environment ecosystem at Shimokawa Lab, Faculty of Science and Engineering, Kyushu Sangyo University.

## Repository Overview

### Core Infrastructure
- **texlive-ja-textlint**: Docker images for Japanese LaTeX compilation with textlint
- **latex-environment**: General LaTeX development environment template with devcontainer
- **latex-release-action**: GitHub Action for automated LaTeX compilation and release creation

### Templates & Tools
- **sotsuron-template**: Unified thesis template (undergraduate 卒業論文 + graduate 修士論文)
- **ise-report-template**: Information Science Exercise report template with HTML/textlint quality management
- **wr-template**: Weekly report template
- **latex-template**: Basic LaTeX template
- **sotsuron-report-template**: Report template for thesis work
- **poster-template**: Academic poster template (A0 size, conference presentations)

### Management & Automation
- **thesis-management-tools**: Administrative tools and documentation for thesis supervision
- **thesis-student-registry**: Student repository registry data (private, data-only)
- **registry-manager**: Registry data management tool (Elixir escript)
- **thesis-monitor**: Student repository monitoring tool (Elixir escript)
- **ai-academic-paper-reviewer**: GitHub Action for automated review via the org-standard AI review workflow; supports both `ACADEMIC` (paper) and `CODE` review modes, so it is the single AI reviewer for the ecosystem
- **ai-reviewer** (legacy): standalone code-review Action hosted at `toshi0806/ai-reviewer` (a fork of `Nasubikun/ai-reviewer`). Superseded by `ai-academic-paper-reviewer` (`CODE` mode) and no longer used by the migrated workflows; kept for reference only
- **aldc**: Command-line tool for adding LaTeX devcontainer to repositories

> **Out of ecosystem scope**: Other repositories that may appear alongside these in a local
> workspace (e.g. `split-sentences`, `ise-report`) are not part of the thesis-environment
> ecosystem and are not managed here.

## Dependency Matrix

```
┌─────────────────────────────────────────────────────────────┐
│                    Dependency Flow                         │
└─────────────────────────────────────────────────────────────┘

texlive-ja-textlint (Docker Base)
    ↓
latex-environment (DevContainer Template)
    ↓
├── sotsuron-template (Student Templates)
├── ise-report-template (HTML-based quality-focused)
├── wr-template
├── latex-template
├── sotsuron-report-template
└── poster-template

Supporting Infrastructure:
├── latex-release-action → (Used by templates)
├── ai-academic-paper-reviewer → (AI review for thesis repos & code review, ACADEMIC/CODE modes)
├── aldc → latex-environment (release branch)
├── thesis-management-tools → (Management workflows)
├── thesis-student-registry → (Student repository registry data, private)
├── registry-manager → thesis-student-registry (writes registry data)
└── thesis-monitor → thesis-student-registry (reads registry data)
```

## Version Compatibility

| Component | Current Version | Compatible With | Update Frequency |
|-----------|----------------|-----------------|------------------|
| texlive-ja-textlint | 2026a | TeXLive 2026 | Annual (TeXLive release) |
| latex-environment | release branch | texlive-ja-textlint:2026a | Auto (on merge to main) |
| sotsuron-template | Latest | Auto-updated via aldc | No manual updates needed |
| ise-report-template | Latest | Auto-updated via aldc | No manual updates needed |
| latex-template | Latest | Auto-updated via aldc | No manual updates needed |
| wr-template | Latest | Auto-updated via aldc | No manual updates needed |
| sotsuron-report-template | Latest | Auto-updated via aldc | No manual updates needed |
| poster-template | Latest | Auto-updated via aldc | No manual updates needed |
| latex-release-action | v3.3.0 | All templates | Per feature |
| aldc | Latest | latex-environment:release | No updates needed |
| ecosystem_manager | Latest | Elixir ~> 1.17 (OTP 27+) | Per feature |

## Automated Update Chain

```
1. texlive-ja-textlint update (manual tag creation)
   ↓
2. latex-environment auto-detects and creates PR  
   ↓  
3. Manual PR review and merge to main branch
   ↓
4. latex-environment release branch updated automatically
   (update-release-branch workflow on merge to main)
   ↓
5. aldc automatically uses updated release branch
   ↓
6. New student repositories automatically get latest environment
   ↓
7. Templates require no manual updates (aldc integration)
```

## Management Principles

### 1. **Loose Coupling**
- Each repository maintains independence
- Clear interfaces between components
- Minimal hard dependencies

### 2. **Progressive Enhancement**  
- Core functionality works without optional components
- Additional features layer on top cleanly
- Graceful degradation when dependencies unavailable

### 3. **Student-First Design**
- Simple setup process (one-liner with Docker)
- Self-service repository creation
- Automatic environment configuration

### 4. **Faculty Workflow Integration**
- Review system built into GitHub
- Automated suggestion workflows
- Minimal manual intervention required

### 5. **Organization-Scoped Deployment**

The ecosystem operates **per GitHub organization**: one organization is one
deployment unit, holding its own registry data repository, student
repositories, and automation. The tools are distributed as code; the
deployment identity lives in the organization, never in the code.

- **Location by convention**: the registry data repository is
  `<org>/thesis-student-registry`. The organization is always derived from
  the runtime context — `github.repository_owner` in GitHub Actions,
  `ORGANIZATION` in create-repo scripts, `github_org` in tool configs.
  Code must not contain a literal organization name as the effective default —
  that is, as a value the tools actually fall back to at runtime. Literals in
  test fixtures, documentation samples, and a clearly-marked local-only
  fallback (where no runtime context exists) are acceptable.
- **Deviation by configuration**: deployments that depart from the
  convention override it per deployment — the org-level Actions variable
  `REGISTRY_REPO` for automation, and per-tool overrides
  (`--registry-repo` flag / environment variable / local config) for CLIs.
  Setting the variable to an empty string disables the override (falls back
  to the convention).
- **Fork-clean guarantee**: cloning or forking the tool repositories into
  another organization must work **without editing distributed code**.
  Committing a deployment's identity into a tool repository is therefore
  not allowed (it would force forks to diverge).
- Local tool configs (`~/.config/registry-manager/config.json`,
  `~/.thesis-monitor.yml`) are a local record of this decision plus
  machine-local details (checkout paths); the org context remains the
  source of truth.

## Template Specialization

### Document Format Focus
- **sotsuron-template**: LaTeX-based academic thesis with advanced typesetting
- **ise-report-template**: HTML-based reports with web accessibility and quality automation
- **wr-template**: Weekly progress reports with structured formatting
- **latex-template**: Minimal LaTeX setup for general academic documents
- **poster-template**: A0-sized academic posters using tikzposter with LuaLaTeX

### Quality Management Approaches
- **ise-report-template**: Comprehensive quality pipeline (HTML5 validation, accessibility checks, textlint for Japanese)
- **sotsuron-template**: Academic writing standards with citation management
- **wr-template**: Structured progress tracking with consistent formatting
- **latex-template**: Basic LaTeX quality assurance
- **poster-template**: Automated PDF generation with visual design validation

### Target Audiences
- **ise-report-template**: Information Science Exercise students (HTML proficiency development)
- **sotsuron-template**: Undergraduate/graduate thesis students (research document preparation)
- **wr-template**: Research students and faculty (progress tracking)
- **latex-template**: General academic users (basic LaTeX needs)
- **poster-template**: Researchers presenting at conferences and symposiums

## Cross-Repository Standards

### Terminology: Student Repository Registry

The ecosystem uses **"registry"** consistently for the student-repository ledger:

- **Registry**: the ledger of student repositories, materialized as `data/registry.json`
  (renamed from `repositories.json` in 2026-07; tools keep a one-generation fallback)
  in the registry data repository. Use "registry (data)" in docs — avoid ad-hoc synonyms
  such as "student data", "student repository list", or "リポジトリ一覧" for the same thing.
- **Registry data repository**: `thesis-student-registry` (private, data-only).
  Test counterpart: `thesis-student-registry-test` (naming rule: `<production-name>-test`).
- **Tool naming**: prefix = the object the tool operates on, suffix = its role
  (read = *monitor*, write = *manager*). Hence `registry-manager` writes the registry,
  while `thesis-monitor` reads the registry as an index to monitor student thesis
  repositories. The prefix asymmetry is intentional — the two tools operate on
  different objects.
- **Data fields**: registry-managed timestamps carry the `registry_` prefix
  (`registry_created_at`, `registry_updated_at`); bare `created_at`/`updated_at` are
  legacy fields (see registry-manager data-structure spec for migration status).
- **`repository_type` vocabulary**: `sotsuron` (undergraduate thesis), `master`
  (master's thesis), `wr`, `ise` (the stored value; `ise-report` is accepted as an alias), `latex` (latex-template-derived,
  branch-tracked — conference papers etc.), `other`. The word `thesis` is **not**
  a repository_type: it lives in other layers only — the `DOC_TYPE=thesis`
  document flow, the "all theses" filter (`--type thesis` = sotsuron ∪ master),
  and historical repo-name suffixes (real master theses are named `*-master`).
  Decision record: smkwlab/thesis-management-tools#471.
- **Disambiguation**: "registry" in container/image contexts (texlive-ja-textlint,
  devcontainer docs) means **GitHub Container Registry (ghcr.io)** and is unrelated;
  always spell it out fully there.

### File Naming Conventions
- **CLAUDE.md**: Project-specific Claude Code instructions
- **README.md**: User-facing documentation  
- **CHANGELOG.md**: Release history (where applicable)
- **.devcontainer/**: VS Code development environment

### Branch Strategy
- **main**: Development and source of truth
- **release**: Clean template for user consumption (latex-environment only)
- **feature branches**: Development work, PR-based workflow

### Tagging Strategy  
- **Semantic versioning**: v{MAJOR}.{MINOR}.{PATCH}
- **Calendar versioning**: For texlive-ja-textlint (e.g., 2025b)
- **Coordinated releases**: Major ecosystem updates

## Development Workflow

### For Infrastructure Changes
1. Update base component (texlive-ja-textlint)
2. Test in latex-environment
3. Propagate to templates
4. Update documentation

### For Template Changes
1. Develop in template repository
2. Test with current environment
3. Ensure compatibility across thesis types
4. Update related documentation

### For Tool Development  
1. Develop in respective tool repository
2. Test against multiple templates
3. Update integration documentation
4. Consider automation opportunities

## Quality Assurance

### Automated Testing
- **texlive-ja-textlint**: Multi-architecture builds, LaTeX compilation tests
- **latex-environment**: DevContainer validation, extension loading
- **Templates**: Sample document compilation, textlint validation
  - **ise-report-template**: HTML5/CSS quality validation, accessibility checks, Japanese academic writing standards
- **Actions**: Integration tests with sample repositories

### Manual Validation
- Student workflow end-to-end testing
- Faculty review process validation  
- Cross-platform compatibility (Windows/macOS/Linux)
- Performance regression testing

## Emergency Procedures

### Rollback Strategy
1. **Immediate**: Revert problematic component to previous version
2. **Communication**: Update status in relevant repositories
3. **Investigation**: Root cause analysis in issue tracker
4. **Prevention**: Update automated tests to catch similar issues

### Hotfix Process
1. Create hotfix branch from last known good state
2. Apply minimal fix with thorough testing
3. Fast-track review process
4. Deploy with monitoring

## Monitoring & Metrics

### Health Indicators
- Student repository creation success rate
- Environment setup failure rate  
- Compilation success rate across templates
- Review system adoption metrics

### Performance Metrics
- Container build times
- Repository setup duration
- Document compilation speed
- Action execution times

## Future Roadmap

### Short Term (3 months)
- [ ] Implement cross-repository testing
- [x] Enhance dependency update automation (check-texlive-updates workflow + Renovate across repos)
- [ ] Improve error reporting and diagnostics

### Medium Term (6 months)  
- [ ] Multi-language template support
- [ ] Enhanced AI review capabilities
- [ ] Student progress analytics

### Long Term (12 months)
- [ ] Cloud-based compilation service
- [ ] Real-time collaboration features
- [ ] Advanced template customization

## Contributing Guidelines

### Cross-Repository Changes
1. Create issues in all affected repositories
2. Coordinate changes through main tracking issue
3. Test integration points thoroughly
4. Update this document as needed

### Documentation Standards
- Keep ECOSYSTEM.md updated with architectural changes
- Maintain README.md in each repository
- Use English for all public-facing documentation
- Include migration guides for breaking changes

## Support & Contact

- **Primary Maintainer**: Kyushu Sangyo University LaTeX Team
- **Issue Tracking**: Individual repository issues for component-specific problems
- **Ecosystem Issues**: Use latex-environment repository for cross-cutting concerns
- **Emergency Contact**: Create issue with `urgent` label in relevant repository

---

*Last Updated: 2026-07-04*  
*Document Version: 1.2*