# Feature Development Guidelines

## Overview
This document defines the mandatory process for developing new features and significant changes in the Fasti project. All non-trivial functionality additions must follow the planning-based development approach outlined here.

## Development Planning Requirements

### Mandatory Planning Documentation
**All feature development must begin with a comprehensive development plan.**

- **Location**: `docs/plans/` directory
- **Format**: Markdown (.md) files
- **Naming Convention**: `[feature-name] - Fasti Development Plan`
- **File Naming**: Use kebab-case (lowercase with hyphens) for filenames

### Planning Document Structure
Each development plan must include:

1. **Title**: `# [Feature Name] - Fasti Development Plan`
2. **Overview**: Clear description of what the feature accomplishes
3. **Goals**: Specific, measurable objectives
4. **Current Architecture**: Existing system state before changes
5. **Target Architecture**: Desired system state after implementation
6. **Development Phases**: Step-by-step implementation breakdown
7. **Technical Implementation Details**: Code examples, API changes, data structures
8. **Design Decisions**: Document significant architectural or interface choices (see ADR section below)
9. **Risk Assessment**: Potential issues and mitigation strategies
10. **Success Criteria**: Checklist of completion requirements
11. **Files to Modify/Create**: Complete list of affected files
12. **Breaking Changes**: Documentation of compatibility impacts
13. **Migration Examples**: User-facing change guidance

### Feature Classification
**Requires Development Plan:**
- New CLI options or argument processing changes
- Data structure modifications (Options, configuration formats)
- Breaking changes to existing interfaces
- Integration of new dependencies or libraries
- Significant refactoring affecting multiple files
- Changes to core calendar logic or output formatting

**May Skip Planning (Use Discretion):**
- Bug fixes that don't change interfaces
- Documentation updates
- Test additions for existing functionality
- Minor style or formatting improvements

## Development Process

### Phase 1: Planning
1. **Create Development Plan**
   - Write comprehensive plan document in `docs/plans/`
   - Follow established naming conventions and structure
   - Include all required sections with appropriate detail
   - Consider dependencies between features

2. **Plan Review**
   - Verify plan completeness against checklist
   - Ensure technical approach is sound
   - Confirm breaking changes are documented
   - Validate migration path for users

### Phase 2: Implementation
1. **Branch Creation**
   - Create feature branch matching plan filename
   - Branch name format: `feature/[plan-filename-without-extension]`
   - Example: `positional-arguments.md` → `feature/positional-arguments`

2. **Plan Commitment**
   - Commit development plan to feature branch first
   - Use descriptive commit message referencing the feature
   - Plan serves as implementation roadmap and documentation

3. **Phase-by-Phase Implementation**
   - Follow development phases outlined in plan
   - Make atomic commits for each logical step
   - Update plan if significant deviations are necessary
   - Maintain focus on success criteria throughout

### Phase 3: Quality Assurance
1. **Testing Requirements**
   - All functionality must pass existing test suite
   - Add new tests for new functionality
   - Ensure RuboCop compliance
   - Verify documentation accuracy

2. **Documentation Updates**
   - Update README.md with new functionality
   - Update CLI help text and examples
   - Provide migration guidance for breaking changes
   - Ensure all public APIs are documented

### Phase 4: Integration
1. **Pull Request Creation**
   - Reference development plan in PR description
   - Include comprehensive testing evidence
   - Document any deviations from original plan
   - Provide clear migration instructions

2. **Review Process**
   - Verify implementation matches plan objectives
   - Confirm all success criteria are met
   - Validate breaking change documentation
   - Test migration scenarios

## Planning Document Standards

### Branch Integration
- **Branch Name**: Must match plan filename (without .md extension)
- **Prerequisite Plans**: Reference dependent plans explicitly
- **Development Order**: Document if features must be implemented in specific sequence

### File Naming Examples
```
docs/plans/positional-arguments.md     → feature/positional-arguments
docs/plans/structured-config.md        → feature/structured-config
docs/plans/color-theme-support.md      → feature/color-theme-support
```

### Cross-Reference Format
When referencing other plans:
```markdown
**Prerequisite**: Complete implementation of positional arguments (see `positional-arguments.md`) before starting this feature.
```

## Template Usage

### Required Sections Template
```markdown
# [Feature Name] - Fasti Development Plan

## Overview
[Brief description of the feature and its purpose]

## Goals
1. **[Primary Goal]**: [Description]
2. **[Secondary Goal]**: [Description]

## Current Architecture
[Description of existing system state]

## Target Architecture
[Description of desired system state]

## Development Phases
### Phase 1: [Phase Name]
**Branch**: `feature/[branch-name]`

1. **[Step Name]**
   - [Detailed implementation steps]
   
## Success Criteria
- [ ] [Measurable completion requirement]
- [ ] [Another requirement]

## Files to Modify
- `[file-path]` - [Description of changes]

## Breaking Changes
- **[Change Type]**: [Description and impact]

## Design Decisions
### [Decision Topic]
**Decision**: [What was decided]

**Alternative Considered**: [Alternative approaches that were evaluated]

**Rationale**: 
- [Key reasoning point 1]
- [Key reasoning point 2]

**Trade-offs**: 
- [What was gained vs what was sacrificed]
```

## Architecture Decision Records (ADR)

### Design Decision Documentation
**All significant design decisions must be documented in the plan's "Design Decisions" section.**

This serves as a lightweight Architecture Decision Record (ADR) approach:
- **Preserves reasoning**: Future developers understand why choices were made
- **Prevents re-debate**: Avoided repeatedly revisiting settled decisions  
- **Facilitates reviews**: Reviewers can evaluate decision quality
- **Enables evolution**: Clear context for when decisions need revisiting

### What Constitutes a Significant Decision
Document decisions about:
- **Interface design**: CLI argument structure, API signatures
- **Data structures**: How information is organized and passed
- **Architecture patterns**: Parsing order, validation approach
- **User experience**: Error handling, default behaviors
- **Technology choices**: Libraries, frameworks, approaches

### Decision Documentation Format
For each significant decision:
1. **State the decision clearly**
2. **List alternatives considered** 
3. **Provide concrete rationale** with specific benefits/drawbacks
4. **Acknowledge trade-offs** - what was sacrificed for what was gained

### Example Reference
See `positional-arguments.md` "Design Decisions" section for a good example of documenting the choice between fixed vs automatic argument ordering.

## Quality Standards

### Plan Completeness
Every development plan must be comprehensive enough that:
- Another developer can understand the full scope
- Implementation steps are clear and actionable
- Success criteria are measurable and specific
- Risk mitigation strategies are identified

### Maintenance Requirements
- Update plans when implementation reveals new requirements
- Keep plans synchronized with actual implementation
- Archive completed plans as project documentation
- Reference plans in related code comments where appropriate

## Integration with Existing Workflows

### Git Workflow Integration
- Development plans integrate with established git workflow (see `git-workflow.md`)
- Commit message format applies to plan commits
- Pull request process includes plan review

### Code Quality Integration
- Plans must consider RuboCop compliance (see `code-quality.md`)
- Implementation phases include quality gate checkpoints
- Testing requirements align with project standards

### Project Conventions Integration
- Plans must follow file organization standards (see `project-conventions.md`)
- Naming conventions apply to all plan-related artifacts
- Documentation requirements include plan maintenance

---
*This document serves as the authoritative guide for feature development planning in the Fasti project. All contributors must follow this process for significant functionality changes.*