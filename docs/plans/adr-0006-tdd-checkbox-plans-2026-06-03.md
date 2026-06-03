# ADR-0006: TDD Checkbox Plans Skill (Advisory)

- Status: Accepted
- Date: 2026-06-03
- Supersedes: —
- Source RFC: [RFC-0005](../rfc/rfc-0005-tdd-checkbox-plans-2026-06-03.md)

## Context

Every plan in `multi_trip_construct/docs/superpowers/plans/` (14 files,
April 2026) follows a strict per-task ladder: write red test → run to
verify it fails with a *predicted* error fragment → minimal
implementation → run to verify it passes → commit. The structure forces
TDD adoption (you can't skip the red-test step without an obvious
unchecked checkbox), bakes verification into the plan, and survives
interruption.

The agent-skillset already has `writing-plans` and `executing-plans`
skills. Neither encodes the strict red-gate-before-implementation
rhythm with explicit failure-fragment prediction. The 2026-06-03
grilling settled three structural points up front:

- The skill is **advisory**, not mandatory — small features and tests
  that touch shared mutable state (live DBs, queues, services) opt out.
- The ladder is **external memory**, not a tracked doc file. The
  project taxonomy is RFC (drafts) / ADR (decisions) / external memory
  (ephemeral execution state). Standalone date-prefixed "plan" files
  have no home.
- Recovery from lost external memory must be documented: agents
  reconstruct progress by reading the originating ADR + the repo state.

[RFC-0005](../rfc/rfc-0005-tdd-checkbox-plans-2026-06-03.md) drafted the
proposal; OQs were grilled to convergence on 2026-06-03.

## Decision

Ship `skills/tdd-checkbox-plans/` with the following settled choices:

1. **Ladder is external memory; placement is per-execution.** The
   skill's `references/task-template.md` defines the ladder shape. The
   live ladder lives in agent session scratch (or
   `.agents/in-progress/<branch>.md` for cross-session work, never
   merged to main). When implementation completes, verification records
   are folded into the related ADR's "Verification" section. Each ADR
   implemented via this skill mentions the skill in its
   "Implementation" section.

2. **Recovery procedure documented in `references/recovery.md`.** If
   external memory is lost, the agent reconstructs progress from:
   (1) the originating RFC and ADR, (2) the repository state — tests on
   disk, new symbols, `git log` on the feature branch, (3) the task
   template re-derived from the ADR's acceptance criteria. The ADR's
   Verification section is the durable handle for reconstruction.

3. **Mandate explicit `Run:` and `Expected:` sub-bullets in every
   Step-2 verify-red block.** Prose form lets the failure-fragment
   prediction degrade to "should fail"; the explicit form forces the
   author to write down the substring to verify. The skill ships
   `scripts/validate_tdd_plans.py` (sibling of ADR-0005's spec
   validator) that walks ladder files and asserts both bullets.

4. **Every task ends with a Step-5 commit checkbox.** Same forcing
   logic as Q22; pairs with recovery (Q23) since `git log` on the
   feature branch maps 1:1 to completed tasks.

5. **Soft cap of ≤ 10 tasks per ladder; exceeding it is the signal to
   split.** The cap is on the ladder, not the ADR — an ADR with 25
   acceptance criteria is fine; its ladder splits at ~10 into two
   execution rounds rolling up to the same ADR. Recommendation, not a
   block.

6. **Executor choice is a 2×2 of ladder length × ADR risk:**

   | Ladder | ADR risk | Default executor |
   |---|---|---|
   | ≤ 5 tasks | low | main loop, no subagents |
   | ≤ 5 tasks | high | main loop + `executing-plans` checkpoints |
   | 6-10 tasks | low | `subagent-driven-development` (tidy main loop) |
   | 6-10 tasks | high | `subagent-driven-development` + `executing-plans` checkpoints |

   `subagent-driven-development` exists to keep the main loop tidy;
   tidiness pressure scales **with** ladder length, not inversely.
   `executing-plans` is orthogonal — stakes-based, not length-based.
   "High-risk" ADR = its `## Risks` section names destructive,
   hard-to-reverse, or breaking-change operations.

7. **Single up-front confirmation, not a `decision-grilling` walk.**
   Verbatim prompt in `references/propose-and-confirm.md`:

   > "Apply the TDD ladder to this ADR's implementation? Recommended:
   > yes. Opt-outs (record reason in the ADR's Verification section):
   > trivially-small, shared-state-test, pure-refactor, spike."

   On opt-out, the skill records the chosen carve-out reason in the
   ADR's "Verification" section so future readers know why the
   verification record is light. Within a session, the answer is sticky
   per ADR.

## Consequences

**Easier**
- Implementations of accepted ADRs follow a predictable, recoverable
  rhythm.
- `git log` becomes the recovery breadcrumb for lost external memory.
- ADR Verification sections double-duty as the durable execution
  record, removing the need for tracked plan files.

**Harder**
- Authors must write the predicted failure fragment for every Step 2.
  This is the forcing function; the cost is intentional.
- Ladders that exceed 10 tasks must be split, even when the underlying
  decision is genuinely large.
- The skill must coordinate with `executing-plans` and
  `subagent-driven-development` — three skills now form the execution
  triad.

**Constrained**
- No standalone tracked `docs/plans/<date>-<slug>.md` plan files. The
  three-bucket taxonomy (RFC / ADR / external memory) is firm.
- The Step-2 explicit bullets and Step-5 commit are not optional.
- The propose-and-confirm prompt cannot escalate into a multi-question
  walk; the skill stays lightweight by design.

## Verification

```bash
just validate
```

The skill's `scripts/validate_tdd_plans.py` must self-test against a
fixture ladder containing one task with both required bullets and one
without; the validator must accept the first and reject the second.

## Related

- ADR-0001 (Initial Skill Layout) — establishes the
  RFC/ADR/external-memory taxonomy this ADR builds on.
- ADR-0002, ADR-0003, ADR-0004 — each may be implemented via this
  skill; their Verification sections become the durable record of the
  execution that ladder.
- ADR-0005 (Agent Spec Convention) — the structural validator pattern
  is reused here.
