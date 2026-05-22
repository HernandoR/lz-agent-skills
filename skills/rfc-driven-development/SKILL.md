---
name: rfc-driven-development
description: Use when a change may affect architecture, public interfaces, repository workflow, skill layout, long-lived conventions, or other substantive design decisions.
---

# RFC-Driven Development

## Overview

RFCs record decisions before implementation makes them expensive to revisit.
Use them for design choices that future agents or reviewers must understand.

## When An RFC Is Needed

Create or update an RFC before changing:

- Public APIs, data contracts, or cross-language boundaries.
- Repository layout, validation rules, or development workflow.
- Skill taxonomy, skill triggering behavior, or shared conventions.
- Performance claims, benchmark policy, or release gates.
- Any decision where reasonable reviewers may ask "why this shape?"

Do not require an RFC for narrow typo fixes, internal prose edits, or mechanical
metadata updates.

## File Convention

Use this project convention unless local instructions override it:

```text
docs/plans/rfc-{NNNN}-{kebab-title}-{YYYY-MM-DD}.md
```

Maintain `docs/plans/index.md` sorted by RFC ID. Never reuse an ID.

## Template

Use `references/rfc-template.md` as the preferred starting point for new RFCs.
Copy or adapt it into the target project. Existing RFCs are historical records:
do not mass-update older RFCs only because the latest template changed.

## Workflow

1. Check `docs/plans/index.md` and existing RFCs for related decisions.
2. If the decision is already covered, follow or amend that RFC.
3. If not covered, create the next RFC file from the bundled template.
4. Capture alternatives, risks, open questions, and acceptance criteria.
5. Keep implementation commits linked to the RFC when relevant.

## Common Mistakes

- Writing an RFC after implementation as decoration.
- Hiding unresolved decisions in "risks" instead of naming open questions.
- Updating historical RFCs just to match a newer template.

