# ADR-0003: Pydantic Config Tree Skill

- Status: Accepted
- Date: 2026-06-03
- Supersedes: —
- Source RFC: [RFC-0002](../rfc/rfc-0002-pydantic-config-tree-2026-06-03.md)

## Context

`multi_trip_construct` had ~230 hyperparameters scattered across modules,
read from environment variables, hardcoded constants, and ad-hoc config
classes (`MTRWorkflowConfig`, `ClipPreprocessorPathCfg`, …).
Consolidation into a single `MTRConfig` rooted pydantic model with
domain-grouped sub-models, YAML persistence, and an env-var factory took
two superpowers plans (`2026-04-16-integrated-config-system.md`,
`2026-04-17-config-consumer-migration.md`).

The shape — root model, nested sub-models by domain, optional singleton,
YAML round-trip, env-var factory — is a recurring pattern in any
medium-to-large Python pipeline. It is distinct from path config
(ADR-0002) because parameter config carries default values, validation,
persistence, and env-var bindings.

[RFC-0002](../rfc/rfc-0002-pydantic-config-tree-2026-06-03.md) drafted the
proposal; OQs were grilled to convergence on 2026-06-03.

## Decision

Ship `skills/pydantic-config-tree/` with the following settled choices:

1. **Singleton is recommended, not required, and never module-level.** The
   skill exposes singleton hooks as classmethods on the root model:

   ```python
   class MTRConfig(BaseModel):
       @classmethod
       def bind(cls, cfg: "MTRConfig") -> None: ...
       @classmethod
       def current(cls) -> "MTRConfig": ...
       @classmethod
       def reset_for_tests(cls) -> None: ...
   ```

   `bind()` raises if called twice without an intervening `reset`. The
   construction site is a grep-able call (`MTRConfig.bind(MTRConfig.from_env())`)
   at app entry. Module-level `_instance` patterns are explicitly rejected
   because they hide the construction moment.

2. **`pydantic-settings` for env-var loading by default; hand-written
   `from_env()` as a documented fallback** for sparse coverage (≤ 5 vars)
   or migration scenarios where a legacy env-reader (`prod_get_env_value`
   in MTR) must be wrapped during transition.

3. **YAML by default (PyYAML `safe_load` + `model_dump`).** No JSON/TOML
   adapters shipped — the swap is a one-line `import` change documented
   in an appendix. `yaml.safe_load` is mandatory; `yaml.load` is called
   out as the security footgun it is.

4. **Cross-link RFC-0001/ADR-0002, do not share a layout doc.** Each
   skill carries a "Related skills" footer. A future
   `config-module-layout` meta-skill can absorb the overlap if needed
   once both ship.

5. **Flat by default; nest only when a sub-axis owns ≥ 3 fields; hard
   cap at three layers (root → sub-model → sub-sub-model).** The
   template ships flat (root → 5-ish sub-models) with a "when to deepen"
   sidebar. Beyond three layers, env-var paths get unreadable and the
   structure stops paying for itself; the signal is to split the project
   into multiple config trees, not deepen one.

## Consequences

**Easier**
- Adopters get a working `<Project>Config` template with `pydantic-settings`,
  YAML round-trip, and the singleton hooks — no derivation from scratch.
- Migration checklist (three-phase: factory → consumer migration → old-class
  deletion) is documented with the MTR transition as the reference case.
- Singleton stays observable: `MTRConfig.bind(...)` is grep-able from any
  IDE.

**Harder**
- One extra dependency (`pydantic-settings`) — already a transitive dep in
  most pydantic v2 projects but called out explicitly so adopters add it on
  purpose.
- Adopters must understand the singleton-vs-DI trade-off before choosing.
  Mitigated by both shapes being documented.

**Constrained**
- Module-level `_instance = None` patterns are rejected; the singleton
  must be a classmethod hook.
- YAML is the default — adopters who must use JSON/TOML do a one-line
  swap, but no shipped adapter for them.
- Three-layer nesting cap is a hard rule, not a guideline.

## Verification

```bash
just validate
```

The skill's template must compile and type-check under `uvx ty check`
against a synthetic project with one root + two sub-models.

## Related

- ADR-0002 (Centralized Path Config) — companion skill for path
  config; cross-link only.
- ADR-0004 (Loguru-First Logging) — config tree often binds the logging
  level at app entry.
