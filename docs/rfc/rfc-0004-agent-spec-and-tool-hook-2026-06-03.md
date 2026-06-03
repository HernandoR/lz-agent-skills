# RFC-0004: Agent Spec Convention Skill

- Status: Draft
- Date: 2026-06-03
- Owners: liuzhen19

## Summary

Codify the `.agents/spec/<rule>.md` pattern from `multi_trip_construct` as a
reusable skill: a strict schema for project-local agent-readable rules,
located in universally-supported paths (`AGENTS.md` or `.agents/`) so any
agent harness can pick them up without per-tool configuration.

## Discussion Notes

- 2026-06-03 (Q1): Owner confirmed the 5-RFC scope but asked to **drop the
  tool-hook component** of this RFC. Hooks are harness-specific (Kiro,
  Claude Code, Codex each have different formats) and therefore not
  universal. Agent-targeting docs should live in `AGENTS.md` or
  `.agents/` so every harness — current and future — can consume them
  without per-tool wiring. Hook scaffolding may resurface as a separate
  RFC later if a portable hook spec emerges.
- 2026-06-03 (Q17, OQ1): **Specs live at
  `.agents/spec/<rule>.md`. `AGENTS.md` is the inline location for
  short rules.** Reasoning:

  - `.agents/` is the emerging cross-harness convention (Codex,
    Claude Code, Cursor read it; `AGENTS.md` is the de-facto
    single-file equivalent). `docs/` is human-targeted and not
    always loaded by agent harnesses.
  - `.agents/spec/` keeps rule payloads adjacent to other agent
    metadata, leaving room for `.agents/personas/` or
    `.agents/skills/` siblings later.
  - The skill's placement guideline: rules ≤ 30 lines may inline
    in `AGENTS.md` under a dedicated heading; longer rules live in
    `.agents/spec/<rule>.md` with a one-line link from
    `AGENTS.md`.
- 2026-06-03 (Q18, OQ2): **Ship `scripts/validate_agent_specs.py`
  — small, stdlib-only, structural only.** Reasoning:

  - The schema only earns its keep when uniformly applied; without
    a linter, sections drift (one author drops "Why", another
    inlines "References").
  - Scope: walk `.agents/spec/*.md`, assert required H2 headings
    (Rule / Why / Where / Examples / References) appear in order.
    No frontmatter validation, no prose-quality judgement.
  - Dependency-free (stdlib `re` + `pathlib`) so adopters can
    vendor it as easily as the RFC-0001 detector script.
  - Opt-out: a `<!-- agent-spec: skip-section <name> -->` HTML
    comment suppresses the linter for an intentionally-omitted
    section. Documented in the schema reference.
  - Wired into the skill's own `just validate` so the skill ships
    self-tested; adopters are recommended to wire it into
    pre-commit / CI.
- 2026-06-03 (Q19, OQ3): **`AGENTS.md` carries one-paragraph
  summaries + a link, not verbatim includes and not bare links.**
  Reasoning:

  - Some harnesses load only `AGENTS.md` and don't traverse
    relative-path links. A bare link would lose the rule body for
    those harnesses; a one-paragraph summary states the rule
    itself so the rule is enforced even without the linked file.
  - Verbatim include grows `AGENTS.md` past readable size and
    duplicates the spec body, doubling the surface for drift.
  - Drift is bounded by structure: the skill fixes the
    `AGENTS.md` summary shape as
    ```text
    ### <Rule Title>
    <one paragraph stating the rule>

    Full spec: [.agents/spec/<rule>.md](.agents/spec/<rule>.md)
    ```
    Three lines per rule.
  - The Q18 linter extends to check that every `AGENTS.md`
    summary heading has a matching `.agents/spec/<rule>.md` file,
    and that the summary's first sentence matches the spec's
    Rule section verbatim. Drift becomes a CI failure, not a
    silent rot.
- 2026-06-03 (Q20, OQ4): **Require at least one good/bad example
  pair in every spec.** Reasoning:

  - The good/bad pair is what makes a rule actionable — agents
    copy from concrete examples far more reliably than from
    prose. Specs without examples become aspirational documents
    that don't get applied.
  - Cost is one paragraph plus a code block per spec; negligible
    relative to authoring the rule itself.
  - Schema requirement: every spec's `## Examples` section must
    contain at least one block labelled `// BAD` (or
    `# BAD` / `<!-- BAD -->`) and one labelled `// GOOD` (or
    equivalent). The Q18 linter enforces this.
  - Edge case: structural rules (file naming, directory layout)
    can use a non-code "Before / After" pair — directory trees,
    YAML snippets — as the equivalent of code blocks. The schema
    accepts those.
- 2026-06-03 (Q21, OQ5): **Versioning lives in spec frontmatter,
  never in the filename. Git history supplies the change log.**
  Reasoning:

  - Filename suffixes (`no_inline_paths-v2.md`) break every
    cross-reference (`AGENTS.md`, the linter, the harness loaders)
    on each bump — defeating the cross-harness loading promise.
  - Git history alone makes "what version of the rule does this
    commit follow?" archaeology rather than a one-grep answer.
  - Frontmatter is the stable handle. Required fields:
    `name`, `version` (integer, bumped on substantive changes —
    Rule text edits, scope changes; not typo fixes),
    `last_updated` (`YYYY-MM-DD`). Optional:
    `superseded_by: <other-spec-name>` so retired rules can stay
    in place as historical records.
  - The Q18 linter validates the required frontmatter fields and
    flags `superseded_by` chains that don't resolve to existing
    specs.

## Motivation

MTR ships a single concrete instance of the pattern:

- `.agents/spec/no_inline_path_concatenation.md` — the prose rule.
- (Removed from scope) Editor-specific hook files such as
  `.kiro/hooks/no-inline-paths.kiro.hook` are intentionally **out of
  scope** for this skill because hook formats vary across harnesses.

The spec doc alone is high-leverage:

- It stands as the source of truth, readable by humans and agents alike.
- Any harness that already loads `AGENTS.md` / `.agents/` (Claude Code,
  Codex, Kiro, Cursor, …) picks it up automatically.
- It bridges the gap between "documented in CLAUDE.md" (often forgotten)
  and "blocked by lint" (rigid and slow to iterate on), without binding
  to any one editor.

A skill that teaches agents how to author such specs would make this
scaffolding repeatable across projects and rules.

## Goals

- Teach agents the schema for `.agents/spec/<rule>.md` (and the
  equivalent inline section in `AGENTS.md`): Rule, Why, Where (paths in
  / paths out), Examples (good/bad), References.
- Establish the placement convention: long rules live in
  `.agents/spec/<rule>.md`; short rules may inline in `AGENTS.md`
  under a dedicated heading.
- Teach agents how to convert an informal `CLAUDE.md` bullet into a
  spec doc, including how to keep cross-references current.
- Establish the boundary: this skill creates rule-payload scaffolding;
  the rules themselves come from peer skills (RFC-0001, RFC-0003) or
  project-local conventions.

## Non-Goals

- Authoring editor-specific hooks (Kiro, Claude Code, Codex,
  pre-commit). Hooks are harness-specific and excluded by the
  2026-06-03 discussion note above.
- Replacing static lint (ruff/pyright/ty) — agent specs complement them
  by handling rules linters cannot express well.
- Standardising rule semantics across projects. The *scaffolding* is
  reusable; each project's rules stay project-local.

## Proposal

Create `skills/agent-spec-convention/` with:

- `SKILL.md` triggering when an agent is about to:
  - Author or update a project-local enforcement rule (an item that
    would otherwise live in CLAUDE.md), or
  - Convert an informal convention into a structured spec doc.
- `references/agent-spec-schema.md` — the strict schema for
  `.agents/spec/<rule>.md`: Rule, Why, Where, Examples, References.
- `references/placement-guide.md` — when to use inline `AGENTS.md`
  sections versus a dedicated `.agents/spec/<rule>.md` file.
- `references/authoring-guide.md` — how to convert an informal
  CLAUDE.md bullet into a spec, including cross-reference hygiene.
- `references/example-spec.md` — a worked example, e.g. the MTR
  `no_inline_path_concatenation.md` reproduced verbatim with brief
  annotations.

The skill should cross-reference `centralized-path-config` (RFC-0001) and
`loguru-first-logging` (RFC-0003) as canonical examples that ship a
spec doc.

## Alternatives Considered

| Alternative | Why Not |
|---|---|
| Inline rules inside CLAUDE.md only | CLAUDE.md is a Claude-specific name; `.agents/` and `AGENTS.md` are more universal. |
| Per-harness skill (kiro-only, claude-only) | Forks the same idea N ways; agent-targeting docs should be harness-agnostic. |
| Bundle hook scaffolding (original draft) | Hook formats vary across editors; not universal enough — dropped per 2026-06-03 discussion. |

## Risks

- Risk: `.agents/` collision with existing repository metadata. The
  agent-skillset repo already uses `.agents/` for repo metadata; this
  skill clarifies that *target-project* `.agents/spec/` is the rule
  payload directory and is independent of skill-repo `.agents/`.
- Risk: Without a hook, the spec is passive and agents may forget. The
  skill mitigates this by recommending strong cross-links from
  `AGENTS.md` so the spec is loaded by default at session start.

## Open Questions

- OQ1: Should the spec live under `.agents/spec/` (current MTR
  convention) or under `docs/agent-rules/`? Recommended: `.agents/spec/`
  — it's the de-facto convention emerging across harnesses and matches
  the user's preference for `AGENTS.md` / `.agents/` placement.
- OQ2: Should we ship a script that lints spec docs against the schema
  (e.g. required headings present)?
- OQ3: How tightly should `AGENTS.md` mirror or summarise per-spec
  files? Verbatim include vs. one-line link vs. summary block.
- OQ4: Should the skill require at least one good/bad example pair in
  every spec, or recommend it?
- OQ5: How are specs versioned / dated? Filename suffix, frontmatter
  field, or git history only?

## Acceptance Criteria

- [ ] `skills/agent-spec-convention/SKILL.md` exists with a trigger
      description.
- [ ] Schema doc, placement guide, authoring guide, and example spec
      ship in `references/`.
- [ ] No editor-hook templates ship in this skill (see discussion
      note).
- [ ] `just validate` passes.

## Rollout

1. Resolve OQ1–OQ5 in grilling.
2. Author skill scaffolding and references.
3. Land alongside RFC-0001 / RFC-0003 (which provide canonical spec
   contents).
