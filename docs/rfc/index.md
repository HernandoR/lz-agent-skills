# RFC Proposals

This directory holds RFCs (Requests for Comments) — proposals for design
discussion that have not yet reached a settled decision.

RFCs use the template at `skills/write-rfc/references/rfc-template.md`.

## File Naming

```text
rfc-{id}-{kebab-case-title}-{YYYY-MM-DD}.md
```

- `id` is a zero-padded four-digit sequence, independent from ADR IDs.
- `kebab-case-title` is a short slug; prefer six words or fewer.
- `YYYY-MM-DD` is the draft date.

## Current Proposals

| ID | Title | Status |
|---|---|---|

## Process

- Use `skills/write-rfc` to draft a new proposal.
- Once discussion converges, create an ADR in `docs/plans/` via
  `skills/adr-driven-development`.
- Optionally link the resulting ADR back to the RFC for provenance.
- After the ADR is accepted, mark the RFC as `resolved` (do not delete).
