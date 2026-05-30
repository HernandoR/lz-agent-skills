---
name: write-rfc
description: Use when a design idea or proposal needs structured discussion, collecting multiple viewpoints, alternatives, and open questions before a decision is reached.
---

# Write RFC

## Overview

An RFC (Request for Comments) captures a **proposal** for discussion. Unlike an
ADR, which records a decision that has **already been made**, an RFC presents
an idea, explores alternatives, surfaces open questions, and invites
contributors to weigh in. Think of it as the artifact that lives *before* the
decision.

Use `adr-driven-development` to record the final decision once the RFC
discussion converges.

## When An RFC Is Needed

Create an RFC when:

- A design direction is still open and needs broader input.
- Multiple viable approaches exist and trade-offs must be surfaced.
- The change is architecturally significant and reviewers should see the
  reasoning before implementation.
- You want to preserve the discussion history and multi-viewpoint analysis.

Do not create an RFC for:

- Decisions that are already settled — create an ADR instead.
- Trivial changes with no architectural or workflow impact.
- Ideas you already have unilateral authority to decide and execute.

## File Convention

Use this project convention unless local instructions override it:

```text
docs/rfc/rfc-{NNNN}-{kebab-title}-{YYYY-MM-DD}.md
```

Maintain `docs/rfc/index.md` sorted by RFC ID. Never reuse an ID.

## Template

Use `references/rfc-template.md` as the starting point for new RFCs.

## Workflow

1. Identify a design question that would benefit from structured discussion.
2. Draft the RFC from the bundled template, capturing the problem,
   alternatives, risks, and open questions.
3. Share the RFC with reviewers. Incorporate feedback and update the document
   as the discussion evolves.
4. Once the discussion converges on a decision, create an ADR (via
   `adr-driven-development`) to record the settled outcome.
5. Optionally link the ADR back to the RFC for full provenance.

## RFC vs ADR

| | RFC | ADR |
|---|---|---|
| Purpose | Propose an idea for **discussion** | Record a decision **made** |
| Content | Problem → Alternatives → Open Questions | Context → Decision → Consequences |
| Tone | Exploratory, future or conditional tense | Declarative, past or present tense |
| Contains | Multiple viewpoints, discussion process | One settled choice + rationale |
| When | Before or during the decision process | After the decision is settled |

## Common Mistakes

- Treating an RFC as the final word instead of a discussion artifact.
- Writing an RFC for a decision that is already settled — use an ADR.
- Failing to update the RFC as discussion evolves and new information emerges.
- Skipping the follow-up ADR after the RFC discussion converges.
