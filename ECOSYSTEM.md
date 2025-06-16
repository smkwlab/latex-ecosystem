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

### Management & Automation
- **thesis-management-tools**: Administrative tools and documentation for thesis supervision
- **ai-academic-paper-reviewer**: GitHub Action for automated academic paper review using Gemini AI
- **aldc**: Command-line tool for adding LaTeX devcontainer to repositories

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
└── sotsuron-report-template

Supporting Infrastructure:
├── latex-release-action → (Used by templates)
├── ai-academic-paper-reviewer → (Used by thesis repos)  
├── aldc → latex-environment (release branch)
└── thesis-management-tools → (Management workflows)
```

## Version Compatibility

| Component | Current Version | Compatible With | Update Frequency |
|-----------|----------------|-----------------|------------------|
| texlive-ja-textlint | 2025b | TeXLive 2025 | Annual (TeXLive release) |
| latex-environment | v0.5.0 | texlive-ja-textlint:2025b | Per texlive update |
| sotsuron-template | Latest | latex-environment:release | Continuous |
| latex-release-action | v2.2.0 | All templates | Per feature |
| aldc | Latest | latex-environment:release | Per environment update |

## Automated Update Chain

```
1. texlive-ja-textlint update (annual)
   ↓
2. latex-environment auto-detects and creates PR
   ↓  
3. latex-environment release branch updated
   ↓
4. aldc automatically uses new environment
   ↓
5. New student repositories get updated environment
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

## Template Specialization

### Document Format Focus
- **sotsuron-template**: LaTeX-based academic thesis with advanced typesetting
- **ise-report-template**: HTML-based reports with web accessibility and quality automation
- **wr-template**: Weekly progress reports with structured formatting
- **latex-template**: Minimal LaTeX setup for general academic documents

### Quality Management Approaches
- **ise-report-template**: Comprehensive quality pipeline (HTML5 validation, accessibility checks, textlint for Japanese)
- **sotsuron-template**: Academic writing standards with citation management
- **wr-template**: Structured progress tracking with consistent formatting
- **latex-template**: Basic LaTeX quality assurance

### Target Audiences
- **ise-report-template**: Information Science Exercise students (HTML proficiency development)
- **sotsuron-template**: Undergraduate/graduate thesis students (research document preparation)
- **wr-template**: Research students and faculty (progress tracking)
- **latex-template**: General academic users (basic LaTeX needs)

## Cross-Repository Standards

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
- [ ] Enhance dependency update automation
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

*Last Updated: 2025-06-13*  
*Document Version: 1.0*