# ADR-0002: Centralized Path Config Skill

- Status: Accepted
- Date: 2026-06-03
- Supersedes: —
- Source RFC: [RFC-0001](../rfc/rfc-0001-centralized-path-config-2026-06-03.md)

## Context

`multi_trip_construct` (MTR) demonstrated that scattering inline path
concatenation (`Path(...) / "literal" / "literal"`) across business logic
turns the storage layout into a refactor minefield. After consolidating
~20 violations across 10 files into a single `src/MTR/configs/path_config.py`
module, the layout became refactorable, IDE-navigable, and lint-able. The
pattern repeats across any project that writes files into a configurable
layout — data pipelines, ETL, ML training, build outputs.

We need a reusable skill so future projects start with this discipline
in place rather than re-deriving it after the inevitable mess.

[RFC-0001](../rfc/rfc-0001-centralized-path-config-2026-06-03.md) drafted
the proposal; the OQs were grilled to convergence on 2026-06-03.

## Decision

Ship `skills/centralized-path-config/` with the following settled choices:

1. **Pydantic v2 frozen models are the primary template.** The skill ships
   pydantic v2 with `model_config = ConfigDict(frozen=True)` as the
   recommended shape, plus a stdlib-`dataclass` fallback in
   `references/dataclass-fallback.md` for projects that cannot take the
   dependency.

2. **Explicit three-axis classification of where path entries live.** The
   skill's `references/extension-decision-tree.md` is authoritative:

   | Layer | What lives here |
   |---|---|
   | Constructor / model fields | Runtime variables that change per process invocation (mount roots, environment IDs, scope IDs, sensor aliases). Caller-supplied. |
   | `@property` (no parameters) | Fixed path agreements: directory and file names chosen by the implementation, stable for a given set of init attributes. Must reuse the nearest existing parent property. |
   | Instance method (parameterised) | Paths whose final segment depends on a value the caller chooses per call (frame id, group id, timestamp). |

   Decision rule: changes-per-run → init attribute; varies-per-call →
   method parameter; otherwise → `@property`. `@staticmethod` is
   forbidden for path generation.

3. **Factory methods on the base config, not module-level free functions.**
   The skill recommends:

   ```python
   class PathConfig(BaseModel):
       def for_poi(self, poi_id: str, mtr_version: str) -> "PoiPaths": ...
       def for_clip(self, clip_adrn: str) -> "ClipPaths": ...
   ```

   This supersedes MTR's `build_clip_paths(...)` / `build_poi_paths(...)`
   module-level free functions. Caching (`@lru_cache`) is documented as an
   optional optimisation knob, not mandated.

4. **Time-derived paths use an optional init-attribute with a
   `default_factory=`.** The skill forbids `datetime.now()` inside a
   `@property` and recommends:

   ```python
   archive_timestamp: str = Field(
       default_factory=lambda: datetime.now().strftime("%Y%m%d_%H%M%S"),
   )
   ```

5. **Detector script ships in both places.** The skill ships
   `scripts/find_inline_paths.sh` (dependency-free, `rg`/`grep -E`); target
   projects copy it into their own `scripts/`. Updates flow skill →
   re-copy. The script accepts `--allow <module-path>` flags to extend
   beyond the default allow-list.

6. **Skill ships its own `.agents/spec/no-inline-paths.md` payload**,
   rewritten (not copied verbatim from MTR) to be repo-agnostic and to
   conform to ADR-0005's spec schema. RFC-0001's payload is the canonical
   worked example referenced by ADR-0005.

## Consequences

**Easier**
- Adopters get a working pydantic-v2 path-config skeleton, the rule
  documentation, the detector script, and a ready-to-drop `.agents/spec/`
  payload — no derivation from scratch.
- IDE navigation (`Go to definition` on a `@property`) resolves to the
  single canonical path agreement.
- Refactoring the storage layout touches one module, not dozens.

**Harder**
- One extra dependency (pydantic v2) for adopters who don't already have
  it. Mitigated by the dataclass fallback.
- Authors must learn the three-axis taxonomy before adding a new path —
  the cognitive cost of doing it right.

**Constrained**
- Path-config classes lose the option of `@staticmethod` builders.
- Module-level `build_*` factories are deprecated; existing MTR-style
  projects keep them as transitional aliases.

## Verification

```bash
just validate
```

The skill must pass repo validation; its detector script must self-test
against a fixture file containing a known violation and pass against a
fixture containing only allowed patterns.

## Related

- ADR-0003 (Pydantic Config Tree) — companion skill for hyperparameter
  config; cross-link only, no shared layout doc per RFC-0002 Q10.
- ADR-0005 (Agent Spec Convention) — supplies the schema this skill's
  `.agents/spec/no-inline-paths.md` payload conforms to.
