# RFC-0005: TDD Checkbox Plans Skill (Advisory)

- Status: Draft
- Date: 2026-06-03
- Owners: liuzhen19

## Summary

Codify the recurring shape of every implementation plan in
`multi_trip_construct/docs/superpowers/plans/` as a reusable skill:
checkbox-tracked TDD ladders where each task explicitly walks "write red
test → run to verify it fails (with the exact expected error message) →
minimal implementation → run to verify it passes → commit".

The skill is **advisory, not mandatory**: agents should propose the TDD
ladder for non-trivial features and explicitly request user confirmation
before applying it. Small features and tasks whose tests would interfere
with shared resources (databases, external services, slow integrations)
opt out.

## Discussion Notes

- 2026-06-03 (Q1): Owner confirmed RFC-0005 is good practice but should
  **not be forced** every session. Some features are too small to justify
  the ladder; some tests can interrupt a database or other shared
  resource. The skill therefore proposes the ladder and waits for the
  user to confirm before applying it; opt-outs are documented in the
  carve-out section below.
- 2026-06-03 (Q22, OQ1): **Mandate the explicit `Run:` and
  `Expected:` sub-bullets in every Step-2 (verify-red) block.**
  Reasoning:

  - The forcing function relies on Step 2 *predicting* a specific
    failure fragment. Prose form lets that prediction degrade to
    "should fail", which doesn't catch plans where the test would
    accidentally green-pass.
  - The structure gives executors (humans or agents resuming a
    paused plan) a grep-able landmark: `Run:` is exactly the
    command to paste; `Expected:` is exactly the substring to
    verify.
  - The skill ships `scripts/validate_tdd_plans.py` (sibling of
    RFC-0004's `validate_agent_specs.py`) that walks plan files
    and asserts each Step-2 block contains both literal bullets.
- 2026-06-03 (Q23, OQ2): **The TDD ladder is external memory, not
  a tracked doc.** Owner clarified the project taxonomy: RFCs in
  `docs/rfc/` (drafts pre-decision), ADRs in `docs/plans/`
  (settled decisions ready to implement), and external memory
  (session-scoped, ephemeral implementation state). Standalone
  date-prefixed "plan" files have no home. Concretely:

  - The skill's `references/task-template.md` defines the *shape*
    of the ladder; placement is per-execution.
  - During implementation the live ladder lives in agent external
    memory (session scratch or, if the work spans sessions, a
    branch-scoped `.agents/in-progress/<branch>.md` that stays on
    the feature branch and never lands on main).
  - When implementation completes, the ladder is either discarded
    or its verification record is folded into the relevant ADR's
    "Verification" section. The ADR is the durable record; the
    ladder is throwaway.
  - Cross-link: each ADR implemented via this skill mentions the
    skill in its "Implementation" section so future readers know
    the verification rhythm that produced it.

  **Recovery from lost external memory:** if the session-scoped
  ladder is lost (crashed agent, new conversation, lost branch
  scratch), the agent reconstructs progress by reading:

  1. The originating RFC and ADR for the decision being
     implemented.
  2. The repository state — completed tests, new types/symbols,
     git log on the feature branch — to determine which ladder
     steps are already on disk.
  3. The skill's task template to re-derive the remaining ladder
     steps from the ADR's acceptance criteria.

  The skill must include a `references/recovery.md` documenting
  this RFC + ADR + repo-state reconstruction sequence so any
  agent picking up the work mid-flight knows the procedure. The
  ADR's "Verification" section therefore double-duties as the
  durable handle external memory can be rebuilt from.
- 2026-06-03 (Q24, OQ3): **Every task ends with an explicit
  Step 5: Commit.** Reasoning:

  - Same forcing-function logic as Q22: a top-of-plan blanket
    statement is easy to skip; a per-task unchecked checkbox is
    impossible to overlook.
  - Matches the rhythm of every MTR plan.
  - The Q22 validator (`scripts/validate_tdd_plans.py`) extends to
    assert each task block contains a commit step.
  - The Q23 recovery procedure benefits directly: when external
    memory is lost, `git log` on the feature branch maps 1:1 to
    completed tasks because each verified task produced exactly
    one commit. Reconstruction is mechanical, not detective work.
- 2026-06-03 (Q25, OQ4 reframed): **Soft cap of ≤ 10 tasks per
  ladder; exceeding it is the signal to split.** Reasoning:

  - MTR's plans run 4-8 tasks typically; the 72 KB
    `2026-04-16-integrated-config-system.md` was the largest and
    later got split into the 41 KB `config-consumer-migration`
    follow-up. That retroactive split is evidence the cap is
    real.
  - The cap is on the **ladder**, not the ADR. An ADR with 25
    acceptance criteria is fine; its ladder splits at ~task 10
    into two execution rounds, both rolling up to the same ADR.
  - Recommendation, not block: the skill's task template includes
    a "When to split" sidebar with the ≤ 10 guideline and the
    prompt "is this really one decision, or two?".
  - Recovery (Q23) benefits: shorter ladders mean shorter
    `git log` reconstructions when external memory is lost.
- 2026-06-03 (Q26, OQ5): **Pick the in-session executor by ladder
  length; decide whether to escalate to a separate-session
  reviewer by ADR risk.** Two orthogonal axes, not one. The
  skill's `references/executor-choice.md` carries this 2×2:

  | Ladder | ADR risk | Default executor |
  |---|---|---|
  | ≤ 5 tasks | low | main loop, no subagents |
  | ≤ 5 tasks | high | main loop + `executing-plans` review checkpoints |
  | 6-10 tasks | low | `subagent-driven-development` (tidy main loop) |
  | 6-10 tasks | high | `subagent-driven-development` + `executing-plans` checkpoints |

  Reasoning:
  - `subagent-driven-development` exists to keep the main loop
    tidy. Tidiness pressure scales **with** ladder length: a
    long ladder accumulates test output, full-file edits, and
    red→green transitions that would otherwise choke the main
    context. Subagents are the right tool for the long case.
  - `executing-plans` is orthogonal: it's about review
    checkpoints between tasks. That's a stakes call (destructive
    ops, breaking changes, data migrations) — independent of
    length.
  - "High-risk" ADR = the ADR's `## Risks` section names
    destructive or hard-to-reverse operations, or breaking API
    changes.
  - Recommendation, not hard rule. The skill stays decoupled
    from both peer skills; a future `execution-policy` meta-skill
    can absorb the matrix if it grows richer.
- 2026-06-03 (Q27, OQ6): **Single up-front confirmation, not a
  full `decision-grilling` walk.** Heavy interaction defeats the
  advisory-and-lightweight point — the user already paid the
  grilling cost when authoring the ADR.

  Interaction shape (verbatim prompt in
  `references/propose-and-confirm.md`):

  > "Apply the TDD ladder to this ADR's implementation?
  > Recommended: yes. Opt-outs (record reason in the ADR's
  > Verification section): trivially-small, shared-state-test,
  > pure-refactor, spike."

  - If "yes" → ladder authored using Q22-Q26's structure; no
    further questions.
  - If opt-out → skill records the chosen carve-out reason in
    the ADR's "Verification" section so future readers (and
    Q23's recovery procedure) know why the verification record
    is light.
  - The skill never re-prompts within a session for the same
    ADR; the answer is sticky.

## Motivation

Inspecting the 14 plans under `docs/superpowers/plans/` shows a consistent
template that every plan reuses:

```
### Task N: <Goal>
**Files:** Modify / Create / Test paths
- [ ] **Step 1: Write the failing test** (with the actual test code)
- [ ] **Step 2: Run test to verify it fails**
       Run: <exact command>
       Expected: FAIL with <exact error fragment>
- [ ] **Step 3: <Minimal implementation>**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**
```

This shape:

- Forces TDD adoption (you cannot skip the red-test step without an
  obvious unchecked box).
- Bakes verification into the plan (Step 2's "expected: FAIL with X"
  catches plans where the test would have green-passed accidentally).
- Splits work into commit-sized atomic units.
- Survives interruption: any agent can resume mid-plan by finding the
  next unchecked box.

The user already has `writing-plans` and `executing-plans` skills, but
neither encodes the strict red-gate-before-implementation rhythm. A
focused skill on this rhythm would bridge the gap.

## Goals

- Teach agents a strict per-task template: red test → verify red →
  minimal impl → verify green → commit, **proposed and confirmed**
  with the user before adoption per task.
- Require Step 2 to predict the *exact* failure fragment (e.g.
  `AttributeError: 'PoiPaths' object has no attribute 'input_data_root'`)
  so the plan author has thought through what's actually missing.
- Keep tasks atomic: one task per public behaviour, one commit per task.
- Cap plans at a manageable size; suggest splitting plans that exceed N
  tasks (TBD in OQ).

## Non-Goals

- Replacing `writing-plans` / `executing-plans` — this skill *composes*
  with them by tightening the per-task structure.
- Forcing TDD on bugfix-only or refactor-only branches where no new
  behaviour is added (the skill carves these out explicitly).
- Mandating pytest specifically — the rhythm works for any test runner.
- Running the ladder by default. The skill is advisory; opt-in per
  session.

## Carve-Outs (When To Skip The Ladder)

The agent should propose the ladder, then skip it when the user
confirms any of:

- **Trivially small change**: a one-line bug fix, a typo, a doc tweak,
  a config bump.
- **Tests would touch shared mutable state**: live databases, queues,
  message brokers, or services where a red-then-green run would
  interrupt other consumers or persist garbage data.
- **Pure refactor with no new behaviour**: snapshot tests apply, not
  red-gate prediction.
- **Spike / exploratory work**: when the goal is to learn the shape of
  the problem, not to land production code yet.

The skill ships a sibling "refactor-checklist" mode for the third
case (snapshot behaviour → refactor → diff snapshot).

## Proposal

Create `skills/tdd-checkbox-plans/` with:

- `SKILL.md` triggering when an agent is about to author an
  implementation plan that adds new behaviour.
- `references/task-template.md` — the strict per-task block schema.
- `references/red-gate-rationale.md` — why the "expected FAIL with X"
  prediction matters and common failure modes when it's omitted.
- `references/example-plan.md` — a worked example adapted from one of
  the MTR plans (e.g. `2026-04-17-path-property-consolidation.md`).

The skill should cross-reference `verification-before-completion`,
`writing-plans`, and `executing-plans`.

## Alternatives Considered

| Alternative | Why Not |
|---|---|
| Add to `writing-plans` directly | The TDD-ladder rhythm is opinionated; some plans (pure refactors) shouldn't follow it. Better as a composable add-on. |
| Generic "checklist plans" skill | Loses the discriminating feature: red-gate prediction. |
| Use TaskMaster-style external tool | Adds dependency; the markdown checkbox format is already universal. |

## Risks

- Risk: Predicting the exact FAIL fragment adds plan-authoring time.
  Mitigation: skill emphasises this is a forcing function — the cost
  pays back in catching bugs in the plan itself.
- Risk: Refactor / migration plans don't fit the red-gate rhythm.
  Mitigation: skill defines a sibling "refactor-checklist" carve-out
  with steps "snapshot behaviour → refactor → diff snapshot".
- Risk: Forcing the ladder on every change creates fatigue and breaks
  small fixes. Mitigation: explicit opt-in per session with documented
  carve-outs (see above).

## Open Questions

- OQ1: Should the skill mandate the explicit `Run:` and `Expected:`
  sub-bullets, or accept any equivalent prose?
- OQ2: Should plan files live in a fixed directory (e.g. `docs/plans/`,
  matching `pcl-rustic` and the MTR `docs/superpowers/plans/`)?
- OQ3: Should every task end with a commit step, or is "commit after
  each verified task" stated once at the plan top?
- OQ4: Do we want a soft cap on tasks per plan (e.g. ≤ 10) and a
  recommendation to split larger ones?
- OQ5: How does this skill interact with the existing
  `executing-plans` (separate session w/ review checkpoints) and
  `subagent-driven-development` (current session w/ subagents)? Should
  the skill prescribe one default executor?
- OQ6: How exactly does the skill *propose-and-confirm*? Inline
  question + recommended answer (matching `decision-grilling`), or a
  fixed boilerplate prompt at the top of every plan it authors?

## Acceptance Criteria

- [ ] `skills/tdd-checkbox-plans/SKILL.md` exists with a trigger
      description.
- [ ] Task template, red-gate rationale, and worked example ship in
      `references/`.
- [ ] `just validate` passes.

## Rollout

1. Resolve OQ1–OQ5 in grilling.
2. Author skill files.
3. Land independently of RFC-0001..RFC-0004.
