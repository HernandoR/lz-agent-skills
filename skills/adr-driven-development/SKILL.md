---
name: adr-driven-development
description: Use when a design decision has been made and should be recorded as a lightweight Architecture Decision Record (ADR) that future contributors can reference.
---

# ADR-Driven Development

## Overview

An Architecture Decision Record (ADR) captures a single design decision that has
been **made**, along with its context, rationale, and consequences. ADRs are
lightweight, immutable records — they document what was decided and why, not
what was discussed along the way.

Follow the conventions at <https://adr.github.io/>. Each ADR records a
justified design choice that addresses a functional or non-functional
requirement significant to the architecture, workflow, or long-term
maintainability of the project.

## When An ADR Is Needed

Create an ADR after a decision is **settled** for:

- Public APIs, data contracts, or cross-language boundaries.
- Repository layout, validation rules, or development workflow.
- Skill taxonomy, skill triggering behavior, or shared conventions.
- Performance claims, benchmark policy, or release gates.
- Any decision where future contributors may ask "why was it done this way?"

Do not create an ADR for:

- Narrow typo fixes, internal prose edits, or mechanical metadata updates.
- Ideas still under discussion — use `write-rfc` for proposals that need
  broader input before a decision.

## File Convention

Use this project convention unless local instructions override it:

```text
docs/plans/adr-{NNNN}-{kebab-title}-{YYYY-MM-DD}.md
```

Maintain `docs/plans/index.md` sorted by ADR ID. Never reuse an ID.

## Template

Use `references/adr-template.md` as the starting point. The template follows
the [Nygard format](https://adr.github.io/) with optional extensions for
project-specific metadata.

## Workflow

1. Once a decision is settled (after RFC discussion, team review, or individual
   judgment call), check `docs/plans/index.md` for related ADRs.
2. If the decision is already recorded, do not duplicate. Amend the existing
   ADR if the decision changed.
3. Otherwise, create the next ADR file from the bundled template.
4. Set the status to `accepted` and capture context, decision, and
   consequences.
5. Reference the ADR from relevant implementation commits.

## Status Values

- `proposed` — drafted but awaiting final sign-off.
- `accepted` — the decision is in effect.
- `rejected` — considered but intentionally not adopted.
- `deprecated` — no longer in effect (superseded or withdrawn).
- `superseded` — replaced by a later ADR (link the replacement).

## ADR vs RFC

| | ADR | RFC |
|---|---|---|
| Purpose | Record a decision **made** | Propose an idea for **discussion** |
| Content | Context → Decision → Consequences | Problem → Alternatives → Open Questions |
| Tone | Declarative, past or present tense | Exploratory, future or conditional tense |
| Contains | One settled choice + rationale | Multiple viewpoints, discussion process |
| When | After the decision is settled | Before or during the decision process |

Use `write-rfc` to draft a proposal that needs broader input. Create an ADR
once the RFC discussion converges on a decision.

## Common Mistakes

- Writing an ADR before the decision is actually settled.
- Recording every micro-decision instead of architecturally significant ones.
- Failing to link a superseded ADR to its replacement.
- Confusing ADR (record of a decision) with RFC (proposal for discussion).
