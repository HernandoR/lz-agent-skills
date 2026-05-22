# AGENTS.md

Guidance for AI coding agents working in this skills repository. Human-facing
project documentation should stay in tracked docs; `.agents/` is reserved for
metadata about this repository and must not be used as the installable skill
payload location.

## Project Overview

This repository contains reusable Codex skills. Installable skill packages live
under top-level `skills/<skill-name>/`. Each skill is independent, but related
skills may cross-reference each other.

The repository follows conventions learned from `pcl-rustic`:

- Prefer RFCs for substantive design changes.
- Use Context7 through a subagent for unknown external APIs or APIs without
  local examples.
- Treat public interfaces as typed contracts.
- Prefer `uv` for Python tooling and `just` for repeatable commands.
- Resolve open design questions before implementation.
- Commit each verified step instead of batching unrelated work.

## Repository Map

```text
.agents/                  # project metadata only; not installable skills
docs/plans/               # RFCs and their index
scripts/                  # validation and maintenance scripts
skills/                   # installable skill packages
Justfile                  # repeatable project commands
pyproject.toml            # uv-managed Python tooling metadata
```

## Skill Layout

Each skill must use this shape:

```text
skills/<skill-name>/
  SKILL.md
  agents/openai.yaml
  references/             # optional bundled resources
  scripts/                # optional deterministic helpers
  assets/                 # optional output assets
```

`SKILL.md` frontmatter must include `name` and `description`. The folder name
must match the `name`. Descriptions should describe triggering conditions, not
summarize the workflow.

## RFC Workflow

Substantive skill-set, repository-layout, or workflow changes require an RFC in
`docs/plans/`:

```text
docs/plans/rfc-{NNNN}-{kebab-title}-{YYYY-MM-DD}.md
```

RFCs are indexed by ID in `docs/plans/index.md`. Existing RFCs are historical
records; do not update old RFCs only because a newer template exists.

## Commands

Prefer `just` recipes over raw tool commands.

```bash
just validate
just fmt
just ci
```

Python commands in this repo should run through `uv`, for example
`uv run python scripts/validate_skills.py`.

## Git Conventions

- Use short-lived branches when practical.
- Commit each verified logical step.
- Commit subject format: `<type>(<scope>): <subject>`.
- Use Chinese commit subjects for local consistency with the originating
  project conventions.
- Do not skip verification before claiming work is complete.

