# RFC-0002: Pydantic Config Tree Skill

- Status: Draft
- Date: 2026-06-03
- Owners: liuzhen19

## Summary

Codify the pattern from `multi_trip_construct`'s integrated config system as a
reusable skill: a singleton root pydantic model composed of domain-grouped
nested sub-models, with YAML persistence and a `from_env()` factory.

## Discussion Notes

- 2026-06-03 (Q7, OQ1): **Recommend the singleton, do not force it,
  and do not implement it as a module-level instance.** A module-level
  `_instance = None` plus a `get()` accessor makes the construction
  moment opaque — readers can't tell *when* the config was first
  built, only that someone, somewhere, did. Replace that pattern
  with explicit, observable construction:

  - **Recommended pattern (singleton):** the root model exposes a
    classmethod `<Project>Config.bind(cfg)` that registers an
    explicitly-built instance, and `<Project>Config.current()` returns
    it. `bind()` raises if called twice without an intervening
    `unbind()` / `reset_for_tests()`. The construction site is then a
    grep-able call (`MTRConfig.bind(MTRConfig.from_env())`) at app
    entry, not a hidden lazy import.
  - **Opt-out pattern:** pass the config object explicitly through
    constructors. Both patterns work off the same root model; opt-out
    just doesn't call `bind()`.

  The skill ships one template; the singleton hooks are
  classmethods on the root model, not module-level state. This
  preserves the readability of "where is the config built?" while
  giving consumers the convenience of `<Project>Config.current()`.

  Reasoning for not forcing: most adopters won't hit the
  multi-pipeline-per-process corner, but the skill should not block
  them if they do. Recommendation suffices.
- 2026-06-03 (Q8, OQ2): **Use `pydantic-settings` for env-var loading
  by default; keep hand-written `from_env()` as the
  migration-friendly fallback.** Reasoning:

  - `pydantic-settings` (the official spin-off of pydantic v1's
    `BaseSettings`) supplies env-var binding, prefix support
    (`MTR_`), nested-model env-path delimiters
    (`MTR__OPTIMIZATION__PGO_INFO_FROM_ICP=true`), `.env` file
    loading, and CLI integration — type-coerced through pydantic
    itself. Hand-rolling this at MTR's scale (~230 hyperparameters)
    is wasted code.
  - Hand-written `from_env()` is fine when env coverage is sparse
    (≤ 5 vars) or when migrating an existing codebase that already
    reads vars via a custom helper (e.g. `prod_get_env_value` in
    MTR). The skill keeps it as a documented fallback.
  - The skill ships the `pydantic-settings` shape as the primary
    template. The migration checklist shows how to wrap a legacy
    env-reader inside a `BaseSettings` subclass during transition,
    so existing projects can adopt the skill without a big-bang
    rewrite.

  Trade-off: `pydantic-settings` is a separate package — already a
  transitive dep in most pydantic v2 projects, but the skill must
  call it out explicitly so adopters add it on purpose, not by
  surprise.
- 2026-06-03 (Q9, OQ3): **Default to YAML (PyYAML `safe_load` +
  `model_dump`).** TOML/JSON are not shipped as adapters — the
  swap is a one-line `import` and not worth a separate template.
  Reasoning:

  - YAML matches MTR's `configs/integrated_confs/*.yaml` layout and
    the broader ML / data-pipeline ecosystem (Hydra, Ray, k8s
    manifests, GitHub Actions). Multi-line strings, anchors, and
    comments matter for the dozens-to-hundreds-of-fields case this
    skill targets.
  - TOML lacks anchors and is rare for runtime configs (default for
    `pyproject.toml`, seldom for app config).
  - JSON is too verbose for hand editing and forbids comments;
    config files want comments.

  Security: the skill's template uses `yaml.safe_load` exclusively
  (never `yaml.load`) and calls out the difference in its
  reference doc. An appendix explains the JSON/TOML swap for
  adopters who must use those formats.
- 2026-06-03 (Q10, OQ4): **Cross-link RFC-0001 and RFC-0002 — do
  not share a layout doc.** Each skill carries a "Related skills"
  footer linking the other; the actual structural overlap (both
  live under `src/<pkg>/configs/`, both use pydantic) is two
  sentences and not worth a shared reference. A future
  `config-module-layout` meta-skill can absorb the overlap if the
  need becomes clear once both ship.
- 2026-06-03 (Q11, OQ5): **Flat by default; nest only when a
  sub-axis owns ≥ 3 fields; hard cap at three layers
  (root → sub-model → sub-sub-model).** Reasoning:

  - Flat keeps `pydantic-settings` env paths shallow
    (`MTR__OPTIMIZATION__PGO_INFO_FROM_ICP` reads cleanly;
    a fourth `__` would not).
  - MTR's actual layout is one level deep
    (`MTRConfig → {Workflow, Preprocess, Registration,
    Optimization, Reconstruction, ClipSelection}`) and that suffices
    for ~230 fields.
  - Nest only when there are ≥ 3 fields that all depend on the same
    sub-axis (e.g. `Optimization → {gtsam, g2o}` if both engines
    have ≥ 3 of their own knobs).
  - **Three layers max.** Beyond that, names get long, env-var
    paths get unreadable, and the structure stops paying for
    itself. If a fourth layer feels necessary, that's a signal to
    split the project into multiple config trees, not to deepen
    one.

  The skill template ships flat with an explicit "when to deepen"
  sidebar and the three-layer cap stated up front.

## Motivation

`multi_trip_construct` had ~230 hyperparameters scattered across modules,
read from environment variables, hardcoded constants, and ad-hoc config
classes (`MTRWorkflowConfig`, `ClipPreprocessorPathCfg`, …). The
`2026-04-16-integrated-config-system.md` plan consolidated them into a single
`MTRConfig` rooted pydantic model with sub-models grouped by domain
ownership (preprocess, registration, optimization, reconstruction,
clip_selection). The follow-up `2026-04-17-config-consumer-migration.md` then
migrated consumers off the old classes.

The shape — root model, nested sub-models by domain, singleton accessor,
YAML round-trip, env-var factory — is a recurring pattern in any
medium-to-large Python pipeline. It is distinct from path config (RFC-0001)
because parameter config carries default values, validation, persistence,
and env-var bindings.

## Goals

- Teach agents to start a config tree from a single `<Project>Config` root
  model whose fields are typed sub-models grouped by domain ownership.
- Teach agents to expose the singleton via `<Project>Config.get()` /
  `reset()` and avoid metaclass magic.
- Teach agents the YAML round-trip pattern (`load_config(path)` /
  `save_config(path)`) using pydantic's serialisation.
- Teach agents the `from_env()` factory pattern for runtime overrides.
- Establish migration guidance: keep old config classes as facades during
  transition, delete only after all consumers have moved.

## Non-Goals

- Replacing `dynaconf` / `hydra` / `omegaconf` for users who prefer those.
- Mandating singleton access — the skill recommends it but tolerates passing
  the model explicitly.
- Path generation (covered by RFC-0001).

## Proposal

Create `skills/pydantic-config-tree/` with:

- `SKILL.md` whose `description` triggers when an agent is about to:
  - Add a new tunable hyperparameter to a project that already has a
    config module, or
  - Refactor scattered constants / env-var reads into a structured config.
- `references/config-tree-rule.md` — the architectural rule: one root,
  domain-grouped sub-models, singleton, YAML, env factory.
- `references/config-tree-template.py` — a `<Project>Config` skeleton with
  one example sub-model and a `from_env()` factory.
- `references/migration-checklist.md` — phases for migrating an existing
  scattered-config codebase.

The skill should cross-reference `typed-interfaces`,
`centralized-path-config` (paths share the file but live in their own
module), and `uv-python-workflow`.

## Alternatives Considered

| Alternative | Why Not |
|---|---|
| Use `hydra` or `omegaconf` | Heavier dependency; pydantic v2 is already the type-checking story for most projects in scope. |
| Plain dataclass + manual YAML | No validation, no env coercion, more boilerplate. |
| Merge with RFC-0001 path skill | Different mental model (params vs paths) and different operations (load/save vs property tree). |

## Risks

- Risk: A singleton hides dependency injection and complicates testing.
  Mitigation: skill insists on a `reset()` accessor and a `get_config()`
  parameter override path for tests.
- Risk: Over-aggressive migration introduces regressions. Mitigation:
  the `migration-checklist.md` enforces a three-phase pattern (factory →
  consumer migration → old-class deletion) rather than a big-bang
  rewrite.

## Open Questions

- OQ1: Should the singleton be required, or recommended-with-opt-out?
- OQ2: Should `from_env()` ship a generic env-var binder (e.g. via
  `pydantic-settings`) or stay as a hand-written project-specific
  classmethod?
- OQ3: Should the YAML format be fixed (PyYAML safe load + pydantic
  `model_dump`) or pluggable (allow TOML / JSON)?
- OQ4: How tightly should this skill couple to RFC-0001? Cross-link only,
  or share a `references/config-module-layout.md`?
- OQ5: Default depth of nesting — flat (one level under root) vs. deep
  (sub-domains within domains)?

## Acceptance Criteria

- [ ] `skills/pydantic-config-tree/SKILL.md` exists with a trigger
      description.
- [ ] Template file compiles and type-checks under `uvx ty check`.
- [ ] Migration checklist reflects the actual phasing used in
      `2026-04-17-config-consumer-migration.md`.
- [ ] `just validate` passes.

## Rollout

1. Resolve OQ1–OQ5 via grilling.
2. Author skill files.
3. Land after RFC-0001 so cross-references resolve.
