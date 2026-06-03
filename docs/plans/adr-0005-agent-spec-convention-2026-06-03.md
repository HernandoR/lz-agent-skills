# ADR-0005: Agent Spec Convention Skill

- Status: Accepted
- Date: 2026-06-03
- Supersedes: —
- Source RFC: [RFC-0004](../rfc/rfc-0004-agent-spec-and-tool-hook-2026-06-03.md)

## Context

`multi_trip_construct` codifies project rules as `.agents/spec/<rule>.md`
files (e.g. `no_inline_path_concatenation.md`). The pattern bridges the
gap between informal CLAUDE.md bullets (passive, often forgotten) and
strict lint rules (rigid, slow to iterate on), without binding to any
one editor. Any harness that loads `AGENTS.md` / `.agents/` (Claude
Code, Codex, Cursor, Kiro, …) picks the rules up automatically.

The original RFC-0004 draft also proposed shipping editor-specific hook
templates (Kiro, Claude Code, Codex). The 2026-06-03 grilling **dropped
the hook component** because hook formats vary across harnesses and
break the universal-loading promise. The settled scope is the spec doc
convention only.

[RFC-0004](../rfc/rfc-0004-agent-spec-and-tool-hook-2026-06-03.md)
drafted the proposal; OQs were grilled to convergence on 2026-06-03.

## Decision

Ship `skills/agent-spec-convention/` with the following settled choices:

1. **Spec location: `.agents/spec/<rule>.md` for full rules; inline
   under `AGENTS.md` headings for short rules.** Rule-of-thumb: ≤ 30
   lines may inline; longer rules live in their own file with a one-line
   link from `AGENTS.md`. `docs/` is rejected because it isn't always
   loaded by harnesses.

2. **Schema linter ships as `scripts/validate_agent_specs.py` —
   stdlib-only Python, structural only.** It walks `.agents/spec/*.md` and
   asserts required H2 headings (Rule / Why / Where / Examples /
   References) appear in order, plus required frontmatter fields. No
   prose-quality judgement. Opt-out for intentionally-omitted sections:
   `<!-- agent-spec: skip-section <name> -->`.

3. **`AGENTS.md` mirrors specs as one-paragraph summaries + a link**,
   never verbatim include and never bare links. Fixed shape:

   ```text
   ### <Rule Title>
   <one paragraph stating the rule>

   Full spec: [.agents/spec/<rule>.md](.agents/spec/<rule>.md)
   ```

   The linter checks that every `AGENTS.md` summary has a matching
   `.agents/spec/<rule>.md` file and that the summary's first sentence
   matches the spec's Rule section verbatim.

4. **Every spec must include at least one good/bad example pair** in
   its `## Examples` section: a `// BAD` (or `# BAD` / `<!-- BAD -->`)
   block and a `// GOOD` block. Structural rules may use Before/After
   directory trees or YAML snippets in place of code blocks. The linter
   enforces presence of both labels.

5. **Versioning lives in spec frontmatter, never in the filename.**
   Required frontmatter fields: `name`, `version` (integer, bumped on
   substantive changes), `last_updated` (`YYYY-MM-DD`). Optional:
   `superseded_by: <other-spec-name>`. The linter validates required
   fields and resolves `superseded_by` chains.

## Consequences

**Easier**
- Project rules become harness-portable: any agent that reads
  `.agents/` or `AGENTS.md` enforces them automatically.
- The schema + linter prevent silent drift between `AGENTS.md`
  summaries and `.agents/spec/` bodies.
- ADR-0002 and ADR-0004 each ship their canonical spec doc as a
  worked example.

**Harder**
- Spec authors must conform to the schema (Rule / Why / Where /
  Examples / References + frontmatter). Mitigated by the linter giving
  fast feedback.
- The linter is one more script in the repo's CI, with its own
  maintenance.

**Constrained**
- Rules cannot live in `docs/` if they're meant to be agent-loaded.
- Filename versioning is rejected even for major rule rewrites —
  frontmatter and `superseded_by` carry the history instead.
- Editor-specific hook templates are explicitly out of scope; if the
  ecosystem converges on a portable hook spec later, that lives in a
  new ADR, not this one.

## Verification

```bash
just validate
```

The skill must self-test by running its own
`scripts/validate_agent_specs.py` against
`references/example-spec.md` and pass.

## Related

- ADR-0002 (Centralized Path Config) — ships
  `references/agents-spec/no-inline-paths.md` conforming to this
  schema.
- ADR-0004 (Loguru-First Logging) — ships its no-`print` rule as a
  spec doc conforming to this schema.

## Amendments

- 2026-06-03 (RFC-0006): Decision item 2 made the linter language
  explicit ("stdlib-only Python") to match the convention used by
  ADR-0002 / ADR-0004 / ADR-0006 detectors. Behaviour unchanged. See
  [RFC-0006](../rfc/rfc-0006-skill-implementation-deltas-2026-06-03.md).
