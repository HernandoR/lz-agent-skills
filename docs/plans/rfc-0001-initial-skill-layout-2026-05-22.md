# RFC-0001: Initial Skill Layout

- Status: Accepted
- Date: 2026-05-22

## Summary

Create a managed repository for reusable Codex skills with installable skill
payloads under top-level `skills/`, project metadata under `.agents/`, and a
small validation toolchain driven by `just` and `uv`.

## Motivation

The repository should be usable both as a source collection and as a disciplined
development project. It needs enough structure to keep skills valid and
reviewable without turning simple skill authoring into a heavy application
project.

## Decisions

- Store installable skills in `skills/<skill-name>/`.
- Reserve `.agents/` for repository metadata only.
- Require each skill to include `SKILL.md` and `agents/openai.yaml`.
- Validate frontmatter, skill folder/name matching, and UI metadata.
- Track substantive repository and skill-set changes as RFCs in `docs/plans/`.
- Use RFC filenames shaped as
  `rfc-{NNNN}-{kebab-title}-{YYYY-MM-DD}.md`.
- Sort RFCs by ID in `docs/plans/index.md`.
- Seed the repository with focused skills instead of one large generic skill.

## Initial Skill Set

- `development-best-practices`
- `rfc-driven-development`
- `context7-docs-first`
- `typed-interfaces`
- `uv-python-workflow`
- `justfile-workflow`
- `decision-grilling`
- `using-git-worktrees`
- `git-workflow-and-versioning`
- `verification-before-completion`
- `finishing-a-development-branch`

## Consequences

The top-level `skills/` directory is the source of truth for skill payloads.
Project automation stays small: validation checks structure and required
metadata, but it does not judge prose quality.

Existing RFCs are historical records. If the RFC template changes later, agents
must not rewrite older RFCs only to match the latest template.

## Verification

Run:

```bash
just validate
```

