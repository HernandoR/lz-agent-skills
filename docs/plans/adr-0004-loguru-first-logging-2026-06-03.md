# ADR-0004: Loguru-First Logging Skill

- Status: Accepted
- Date: 2026-06-03
- Supersedes: —
- Source RFC: [RFC-0003](../rfc/rfc-0003-loguru-first-logging-2026-06-03.md)

## Context

`multi_trip_construct` standardised on `loguru.logger`, banned `print()`
and stdlib `logging` in business code, and gave every workflow app a
`mtr_log.log` per workspace plus an obvious start banner. The unified
loguru plan (`2026-04-17-unified-loguru-logging.md`) was the single
source of that discipline; the result made log triage and post-hoc
debugging dramatically easier.

The rule is small but high-impact, and AI agents default to `print()`
in Python without explicit guidance.
[RFC-0003](../rfc/rfc-0003-loguru-first-logging-2026-06-03.md) drafted
the proposal; OQs were grilled to convergence on 2026-06-03.

## Decision

Ship `skills/loguru-first-logging/` with the following settled choices:

1. **Ban `import logging` in business code; require an `InterceptHandler`
   reroute at app entry** to capture third-party stdlib loggers
   (urllib3, requests, boto3, torch). Detector
   `scripts/find_stdlib_logging.sh` flags `import logging` and
   `logging.getLogger` outside an allow-list (default
   `<pkg>/log_setup.py`); same in-skill + copy-to-target pattern as
   ADR-0002's path detector.

2. **Banner structure is fixed; field content is project-controlled via
   one hook.** The skill ships:

   ```text
   ============================================================
    <app_name> starting at <timestamp>
    <key1>=<value1>  <key2>=<value2>  ...
   ============================================================
   ```

   `app_name` and `timestamp` are skill-supplied; the project supplies
   `banner_context() -> dict[str, str]`. Hard-coding MTR's specific
   fields would lock adopters out, so only the visual shape is fixed.

3. **Append + loguru rotation is the default file-sink mode.** The
   helper opens with `logger.add(path, rotation="100 MB", retention="7
   days")` and exposes both knobs as kwargs. Truncate-on-start is
   documented as the opt-out for ephemeral CI runs only.

4. **Recommend (don't require) `logger.bind` / `logger.contextualize`
   for structured context, and recommend structured logging in
   general.** The skill ships a worked example (run-scope binding at
   app entry, per-loop binding at major boundaries) and notes
   `serialize=True` as the natural pair for downstream pipeline
   ingestion. No detector ships by default.

5. **Default `enqueue=True` on the file sink** for thread- and
   process-safety. Pure single-threaded tools may opt out for the
   lowest-latency case. The reference doc includes the
   fork-after-`enqueue` footnote (call `setup_file_logging` after
   process pool spawn, or set `multiprocessing.set_start_method("spawn")`).

## Consequences

**Easier**
- Adopters get a uniform banner, file-sink lifecycle, rotation, and
  stdlib-bridge — no derivation from scratch.
- Log triage starts the same way every time across adopting projects.
- Process-pool deadlocks from the fork-after-enqueue race are
  documented up front rather than discovered in production.

**Harder**
- Authors must remember the `InterceptHandler` setup at app entry; if
  forgotten, third-party logs silently bypass the file sink.
- The banner hook contract is one extra method on every app/entry-point
  base class.

**Constrained**
- `import logging` in business code becomes a CI-detectable violation.
- Truncate-on-start is no longer the default; ephemeral CI must opt in
  explicitly.
- File sinks default to `enqueue=True` even when not strictly needed —
  marginal latency cost universally.

## Verification

```bash
just validate
```

The skill's reference file-sink snippet must run end-to-end against a
temp directory: setup → emit → teardown → assert log content + rotation
behaviour.

## Related

- ADR-0003 (Pydantic Config Tree) — config tree often controls the log
  level passed to `logger.add(...)`.
- ADR-0005 (Agent Spec Convention) — the no-`print` rule is published
  as an `.agents/spec/` doc.
