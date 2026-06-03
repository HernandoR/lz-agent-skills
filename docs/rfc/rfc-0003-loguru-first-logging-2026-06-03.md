# RFC-0003: Loguru-First Logging Skill

- Status: Draft
- Date: 2026-06-03
- Owners: liuzhen19

## Summary

Promote the `multi_trip_construct` logging discipline into a reusable skill:
ban `print()` and the stdlib `logging` module in business code, mandate
`loguru.logger`, and provide a per-workspace file-sink + start-banner
scaffolding.

## Discussion Notes

- 2026-06-03 (Q12, OQ1): **Ban `import logging` in business code;
  require an `InterceptHandler` reroute at app entry.** Reasoning:

  - Business code stays unambiguous (`from loguru import logger`
    only) — no `logging.getLogger(__name__)` allowed. Matches the
    MTR rule and avoids the "two logging systems" trap where half
    the messages bypass loguru sinks.
  - Third-party libraries (urllib3, requests, boto3, torch, …)
    emit through stdlib `logging` and can't be refactored. The
    skill mandates a one-liner `InterceptHandler` bridge at app
    entry so their messages still hit the file sink and banner.
  - The skill ships:
    - `references/logging-rule.md` — the ban + cross-references.
    - `references/intercept-stdlib.md` — the canonical
      `InterceptHandler` snippet.
    - `scripts/find_stdlib_logging.sh` — a detector flagging
      `import logging` / `logging.getLogger` outside an
      allow-list (default: `<pkg>/log_setup.py`).

  Detector script follows the same in-skill + copy-to-target
  pattern as RFC-0001's `find_inline_paths.sh`.
- 2026-06-03 (Q13, OQ2): **Banner structure is fixed; field
  content is project-controlled via a single hook.** The skill
  ships a template like:

  ```text
  ============================================================
   <app_name> starting at <timestamp>
   <key1>=<value1>  <key2>=<value2>  ...
  ============================================================
  ```

  with `app_name` and `timestamp` provided by the skill, and a
  project-supplied `banner_context() -> dict[str, str]` hook on
  the app / entry-point base class supplying the trailing
  key=value line.

  Reasoning:
  - The banner's value comes from being recognisable — every
    project's banner has the same shape, so log triage starts the
    same way every time.
  - But context fields are project-specific (POI/version for MTR;
    tenant/run_id for SaaS; commit SHA/image tag for deployables).
    Hard-coding MTR's set would lock adopters out.
  - One hook, one override point — keeps the skill template
    simple and the banner uniform across adopters.
- 2026-06-03 (Q14, OQ3): **Append + loguru rotation is the
  default.** The file-sink helper opens with
  `logger.add(path, rotation="100 MB", retention="7 days")` and
  exposes both knobs as kwargs. Reasoning:

  - Append preserves multi-run breadcrumbs, which matter the most
    on flaky retries (run 3 fails; you want runs 1-2 in the same
    file).
  - Loguru's built-in rotation+retention bounds disk use without
    the truncate footgun (no surprise loss of evidence between
    runs).
  - Truncate-on-start is documented as the opt-out for ephemeral
    CI runs whose log file is uploaded as an artefact and then
    discarded. Not the default; not recommended for local /
    production runs.
- 2026-06-03 (Q15, OQ4): **Recommend `logger.bind` /
  `logger.contextualize` for structured context — and recommend
  structured logging in general.** Reasoning:

  - Structured context is genuinely useful: queryable backends
    (Loki, Elasticsearch, Datadog) treat `bind`-ed fields as
    indexable keys, and trace correlation across services becomes
    trivial. The skill should push adopters that way.
  - Recommendation, not requirement: small projects logging to
    plain files don't pay for it. Forcing every call site through
    `with logger.contextualize(...)` is syntactic cost for
    marginal benefit on those projects.
  - The skill ships:
    - A reference doc explaining when `bind` (per-handler) vs
      `contextualize` (scoped block) is correct.
    - A worked example binding run-scoped fields at app entry and
      per-loop fields at major loop boundaries (per-POI,
      per-clip).
    - A note that JSON-serialised log lines (loguru's
      `serialize=True` sink option) are the natural pair with
      `bind` for downstream pipeline ingestion.
  - Detector: skill suggests grep-recipes for projects that *do*
    want to enforce structured fields on critical log lines, but
    ships none by default.
- 2026-06-03 (Q16, OQ5): **Default `enqueue=True` on the file
  sink.** Reasoning:

  - Modern Python pipelines almost always have some concurrency
    (thread pool for I/O, `multiprocessing.Pool` for CPU,
    `asyncio` for cloud calls). Without `enqueue=True`, the file
    sink risks interleaved writes and — more dangerously —
    `fork`-after-open-handle deadlocks in process pools.
  - `enqueue=True` costs a background queue thread and tens of
    microseconds per log call; free in any realistic workload.
  - Pure single-threaded tools may opt out for the lowest-latency
    case (rare and obvious).

  Fork-safety footnote (added to `references/file-sink-pattern.py`):
  call `setup_file_logging` *after* the process pool is spawned,
  or set `multiprocessing.set_start_method("spawn")`. The
  `fork`-after-`enqueue` race is a documented loguru footgun and
  the skill must call it out.

## Motivation

MTR's `.github/copilot-error-handling-instructions.md`,
`copilot-instructions`, and the `2026-04-17-unified-loguru-logging.md` plan
all converge on the same rule. Mixed logging fragments output across stdout,
stderr, stdlib log files, and loguru sinks; once unified, every workflow
writes to its workspace as `mtr_log.log` and starts with an obvious banner.
That makes log triage and post-hoc debugging dramatically easier.

The rule is small but high-impact and AI agents tend to default to `print()`
in Python — so an explicit skill is worth its weight.

## Goals

- Teach agents to use `from loguru import logger` directly; never `print()`
  in production code; never `import logging`.
- Teach agents the `setup_file_logging(log_dir)` /
  `teardown_file_logging()` lifecycle with **append** mode (never unlink).
- Teach agents the start-banner pattern emitted at app entry, including
  app name + key runtime context fields.
- Teach agents `exc_info=True` for exception logs and structured field
  logging (`logger.bind(...)`) where it pays off.

## Non-Goals

- Forcing loguru into projects that already standardised on `structlog`.
- Mandating a particular log format string.
- Replacing observability tooling (Pyroscope, Sentry, OTel).

## Proposal

Create `skills/loguru-first-logging/` with:

- `SKILL.md` triggering when:
  - An agent is about to add `print()` or `import logging` in
    business code, or
  - An agent is wiring a CLI / app entry point and needs file logging
    + a banner.
- `references/logging-rule.md` — the prose rule.
- `references/file-sink-pattern.py` — a minimal `setup_file_logging` /
  `teardown_file_logging` / `log_start_banner` snippet, derived from the
  `WFApp` base in MTR but generalised.
- `references/exception-logging.md` — `try / except / logger.error(...,
  exc_info=True) / raise` discipline.

## Alternatives Considered

| Alternative | Why Not |
|---|---|
| Stdlib `logging` only | Verbose configuration, no built-in sinks, weaker default formatting. MTR rejected it explicitly. |
| `structlog` | Excellent but heavier; the audience here already uses loguru. |
| Bundle into `development-best-practices` | The rule is concrete enough to deserve its own trigger and template files. |

## Risks

- Risk: `print()` in scripts vs. business code is fuzzy. Mitigation:
  skill carves out `playground/`, `scripts/` (manual one-shots), and
  `__main__` smoke tests.
- Risk: Multiple file sinks accumulate if `teardown` is missed.
  Mitigation: pattern uses a single sink id stored on the app; teardown
  is idempotent.

## Open Questions

- OQ1: Should the skill ban stdlib `logging` outright, or only require
  reroute to loguru via `logger.add(InterceptHandler())`?
- OQ2: Should the start-banner format be fixed (template literal) or
  configurable per-project?
- OQ3: Should `setup_file_logging` use append (MTR default) or truncate
  on each run? Append wins for incident reconstruction; truncate keeps
  log size bounded.
- OQ4: Should the skill require `loguru.logger.bind` for structured
  context, or just recommend it?
- OQ5: How does this interact with multiprocessing / async? MTR uses
  `enqueue=True` for thread safety in workflows — should the skill
  default to that?

## Acceptance Criteria

- [ ] `skills/loguru-first-logging/SKILL.md` exists with a trigger
      description targeting `print()` and `import logging`.
- [ ] Reference file-sink snippet compiles and runs end-to-end against
      a temp directory.
- [ ] `just validate` passes.

## Rollout

1. Resolve OQ1–OQ5 in grilling.
2. Author skill files.
3. Cross-link from `development-best-practices`.
