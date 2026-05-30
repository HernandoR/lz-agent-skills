# ADR-0001: Initial Skill Layout

- Status: Accepted
- Date: 2026-05-22

## Context

We needed a managed repository for reusable Codex skills. The repository should
be usable both as a source collection and as a disciplined development project —
enough structure to keep skills valid and reviewable without turning simple
skill authoring into a heavy application project.

## Decision

- Store installable skills in `skills/<skill-name>/`.
- Reserve `.agents/` for repository metadata only.
- Require each skill to include `SKILL.md` and `agents/openai.yaml`.
- Validate frontmatter, skill folder/name matching, and UI metadata.
- Propose substantive changes via RFCs in `docs/rfc/` and record settled
  decisions as ADRs in `docs/plans/`.
- Use filenames shaped as:
  - `docs/rfc/rfc-{NNNN}-{kebab-title}-{YYYY-MM-DD}.md` for proposals
  - `docs/plans/adr-{NNNN}-{kebab-title}-{YYYY-MM-DD}.md` for decisions
- Sort records by ID in their respective `index.md` files. RFC and ADR IDs are
  independent sequences.
- Seed the repository with focused skills instead of one large generic skill.

## Initial Skill Set

- `development-best-practices`
- `adr-driven-development` (renamed from `rfc-driven-development`)
- `write-rfc` (new, separated from the renamed ADR skill)
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

Existing ADRs are historical records. If the ADR template changes later, agents
must not rewrite older ADRs only to match the latest template.

## Verification

Run:

```bash
just validate
```
