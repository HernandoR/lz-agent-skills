# RFC-0006: Implementation Deltas From Skill Authoring (ADR-0002…0006)

- Status: Draft
- Date: 2026-06-03
- Owners: liuzhen19

## Summary

While implementing the five skills accepted in ADR-0002 through ADR-0006, the
work surfaced four small deltas from those decisions that are worth recording
explicitly before the ADRs are amended:

1. The path-config detector ships as **Python** (`find_inline_paths.py`),
   not the bash variant the ADR named.
2. The detector's pattern flags **any identifier joined with a string-literal
   segment**, not only names ending in `_path`/`_dir`/`_root`. The original
   wording risked silently passing the most common shape (`mount /
   "outputs"`).
3. The default allow-list matches by **basename** (`path_config.py`), not
   only by parent-directory substring. The substring-only form ruled out
   reasonable layouts where the file lives outside `configs/`.
4. The loguru skill's stdlib detector and agent-spec linter ship as Python
   (`find_stdlib_logging.py`, `validate_agent_specs.py`,
   `validate_tdd_plans.py`) using the **same script-style and self-test
   discipline** as the path detector. ADR-0004 named the artifact as a shell
   script (`find_stdlib_logging.sh`); ADRs 0005/0006 did not name a
   language. The deltas are noted here so future cross-references stay
   accurate.

## Motivation

The ADRs were written assuming the original RFC drafts' bash detectors would
ship as-is. The implementation pass found that bash regex with PCRE2 / `grep
-E` portability across `rg` and busybox `grep` is brittle, and that
maintaining the PCRE pattern (with the negative-lookahead, alternation, and
quote-escaping required) is a recurring tax. A stdlib-only Python script:

- runs the same way under any uv-managed project (`uv run python …`);
- has typed regex with `re.VERBOSE` for readability;
- is self-testable inline against fixtures without invoking `rg`/`grep`
  feature flags;
- exits with stable, ergonomic error formatting.

The pattern delta (item 2) is more substantive: the original wording would
have let the most common offending shape through, defeating the rule. The
allow-list delta (item 3) caught a real regression in self-test fixtures
during implementation.

## Proposal

Amend the affected ADRs with explicit notes:

- **ADR-0002 (Centralized Path Config)**:
  - Decision item 5 names `scripts/find_inline_paths.py` (Python,
    stdlib-only) as the shipped detector.
  - Add a sentence stating the regex matches any identifier expression
    joined with `/ "literal"`, not only `_path`/`_dir`/`_root` suffixes.
  - Add a sentence stating the default allow-list matches by basename
    (`path_config.py`, `paths.py`) and supports substring extension via
    `--allow`.

- **ADR-0004 (Loguru-First Logging)**:
  - Decision item 1 names `scripts/find_stdlib_logging.py` (Python,
    stdlib-only) as the shipped detector.

- **ADR-0005 (Agent Spec Convention)**:
  - Decision item 2 explicitly names the linter language as Python,
    stdlib-only (already implied; making it explicit closes ambiguity).

- **ADR-0006 (TDD Checkbox Plans)**:
  - Decision item 3 explicitly names `scripts/validate_tdd_plans.py`
    (Python, stdlib-only).

The implementations themselves match the new wording; the amendments record
the deltas, they do not change behavior.

## Alternatives Considered

| Alternative | Why Not |
|---|---|
| Re-issue ADR-0002…0006 as `superseded_by` and write fresh ADRs | Far too heavy for typo-grade deltas. |
| Leave ADRs unchanged, document only in commit messages | Future readers tracing from ADR → skill find the language mismatch and lose trust in the ADR text. |
| Promote each delta to its own RFC | Each delta is < 5 lines; a single RFC with four bullets is the right granularity. |

## Risks

- Risk: Future skill rewrites flip back to bash on the assumption "the ADR
  said .sh." Mitigation: the amendment is in the Decision section, not a
  footnote.
- Risk: The pattern delta (item 2) is silently re-narrowed by a
  well-meaning future edit ("the regex matches too much"). Mitigation: the
  ADR amendment states the decision and the rationale (the common
  offending shape was bypassed).

## Open Questions

- OQ1: Should ADR-0005's decision text be amended at all, given the linter
  language was implicit? Recommended answer: yes — explicit wording removes
  the only remaining ambiguity in the language-of-shipped-artifacts axis.
- OQ2: Should the four deltas be amended in the existing ADRs, or grouped
  into a single new ADR-0007 that supersedes the relevant lines?
  Recommended answer: amend in place. The deltas are minor enough that an
  in-place note (with this RFC as the source) keeps history readable.

## Acceptance Criteria

- [ ] ADR-0002 amended with the language + pattern + allow-list notes.
- [ ] ADR-0004 amended with the language note.
- [ ] ADR-0005 amended with the language note.
- [ ] ADR-0006 amended with the language note.
- [ ] This RFC's status flips to `Resolved → in-place ADR amendments` once
      the amendments land.

## Rollout

Single commit: this RFC + the four ADR amendments + the skill files (which
are already in tree). Update `docs/rfc/index.md` to list RFC-0006.
