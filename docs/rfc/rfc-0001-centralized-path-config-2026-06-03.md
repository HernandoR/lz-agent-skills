# RFC-0001: Centralized Path Config Skill

- Status: Draft
- Date: 2026-06-03
- Owners: liuzhen19

## Summary

Promote the `multi_trip_construct` "no inline path concatenation" pattern into
a reusable skill. The skill should teach agents to (a) refuse inline
`Path(...) / "literal" / "literal"` patterns in business logic, and (b) extend
a tree of pydantic path-config classes whose `@property` and instance methods
encode every fixed directory and file name agreement in a project.

## Discussion Notes

- 2026-06-03 (Q2): Owner accepted the **pydantic-v2-primary, dataclass-fallback**
  recommendation. The skill ships pydantic v2 frozen models as the
  reference template and bundles a stdlib-`dataclass` fallback for
  projects that can't take the dependency.
- 2026-06-03 (Q2 follow-up): Skill must **explicitly classify** what
  goes where in the path-config tree. The three-axis taxonomy below is
  authoritative and must appear in the skill's `extension-decision-tree.md`:

  | Layer | What lives here | Example from MTR |
  |---|---|---|
  | **Constructor / model fields** (init attributes) | Runtime variables that change per process invocation: mount roots, environment identifiers, POI IDs, MTR versions, clip ADRNs, sensor aliases, version IDs. Anything the *caller* must supply. | `PathConfig.mount_dir`, `PathConfig.env`, `PoiPaths.poi_id`, `PoiPaths.mtr_version`, `ClipPaths.clip_adrn` |
  | **`@property` (no parameters)** | Fixed path agreements: directory and file names chosen by the implementation that are stable for a given set of init attributes. Must reuse the nearest existing parent property — never repeat earlier path segments. | `PoiPaths.poi_export_root`, `PoiPaths.mtr_data_dir`, `PoiPaths.relocate_optimized_submap_poses_json`, `ClipPaths.lidar_odom_json` |
  | **Instance method (parameterised)** | Paths whose final segment depends on a value the caller chooses *per call* (clipset id, frame id, group id, timestamp). Parameters are the values that vary; everything else still derives from init attributes and parent properties. | `PoiPaths.clipset_json(clipset_id)`, `PoiPaths.relocate_cropped_laz(clip_adrn, frame_adrn)`, `ClipPaths.sensor_image(placement, timestamp)` |

  Decision rule:
  1. Does the value change per *process / pipeline run*? → init attribute.
  2. Does the value vary per *call within a run* (e.g. iterating frames)?
     → instance method parameter.
  3. Otherwise it's a fixed agreement → `@property`.

  The skill must also forbid `@staticmethod` for path generation
  (matches the MTR rule) and require every new property/method to
  derive from an existing parent property when one is available.
- 2026-06-03 (Q4, OQ3): **Recommend a factory *method* on the base
  `PathConfig`, not a module-level function.** When the path-config
  tree has more than one scope class (base + `<Scope>Paths` subclasses),
  the skill recommends:

  ```python
  class PathConfig(BaseModel):
      ...
      def for_poi(self, poi_id: str, mtr_version: str) -> "PoiPaths":
          return PoiPaths(poi_id=poi_id, mtr_version=mtr_version, **self.model_dump())

      def for_clip(self, clip_adrn: str) -> "ClipPaths":
          return ClipPaths(clip_adrn=clip_adrn, **self.model_dump())
  ```

  Reasoning:
  - Factory methods stay inside the class hierarchy that owns the
    scope tree, so the skeleton is self-contained — no module-level
    helpers floating beside the classes.
  - Callers discover scope construction via IDE navigation off the
    base config object (`cfg.for_poi(...)`) instead of remembering a
    free function name.
  - Field-set drift is harder: subclasses live next to their factory,
    so any field added on the base is visibly relayed through
    `**self.model_dump()`.

  Caching: when the same scope object is built repeatedly per run
  (e.g. per-frame), wrap the factory body with `@lru_cache` on a
  pure helper, or cache at the call site. Keep the factory method
  itself stateless. The skill does not mandate caching — it documents
  it as the optimisation knob.

  This **supersedes** the original MTR pattern of module-level
  `build_clip_paths(...)` / `build_poi_paths(...)` free functions.
  MTR-style modules can keep their existing functions as deprecated
  aliases that delegate to the new factory methods during migration.
- 2026-06-03 (Q6, OQ5): **Ship a payload spec doc, but rewrite — do
  not copy verbatim from MTR.** The skill bundles
  `references/agents-spec/no-inline-paths.md` as a target-ready
  payload conforming to RFC-0004's schema. It's the canonical
  worked example of an `.agents/spec/<rule>.md` file. **The MTR
  source is a starting point, not a template** — the bundled payload
  must be reviewed and rewritten to:

  - Generalise away MTR-specific class names (`PoiPaths`, `ClipPaths`,
    `mtr_data_dir`, `poi_export_root`) into placeholders
    (`<Scope>Paths`, `<scope>_data_dir`, `<scope>_export_root`).
  - Restate the rule in repo-agnostic terms (e.g. "the path-config
    module" instead of "src/MTR/configs/path_config.py").
  - Replace MTR domain examples with one minimal, neutral example
    plus a pointer back to the skill's main reference for the full
    extension-decision-tree.
  - Conform to whatever schema the RFC-0004 skill settles on (Rule,
    Why, Where, Examples, References).

  RFC-0004 lists this payload as its canonical example spec, so the
  two skills evolve together: schema changes in RFC-0004 trigger a
  payload re-conform here.
  `datetime`-based default** for time-derived paths. Example:

  ```python
  class PoiPaths(PathConfig):
      archive_timestamp: str = Field(
          default_factory=lambda: datetime.now().strftime("%Y%m%d_%H%M%S"),
          description="Stamp captured once at construction; pass explicitly to override.",
      )

      @property
      def poi_archive_path(self) -> Path:
          return self.poi_export_root / "archive" / self.poi_id / f"{self.poi_id}_{self.mtr_version}_{self.archive_timestamp}"
  ```

  Reasoning:
  - Default-factory captures the timestamp once at construction, so the
    `@property` stays a pure derivation from init attributes — `frozen=True`
    invariants hold.
  - Callers who want a deterministic stamp (tests, replays, archive
    reconstructions) override the field; everyone else gets the natural
    "now" default with zero ceremony.
  - One-line field; no method parameter threading through call sites.

  The skill's `extension-decision-tree.md` lists this as the
  recommended shape for time-derived paths and flags
  `datetime.now()`-inside-`@property` as the anti-pattern it replaces.
  skill ships `scripts/find_inline_paths.sh` as the canonical
  implementation; target projects copy it into their own `scripts/`
  and wire it into pre-commit / CI. Updates flow: skill → re-copy.
  The script is dependency-free (uses `rg` or `grep -E`) and accepts
  `--allow <module-path>` flags to extend the allow-list beyond the
  default `src/<pkg>/configs/path_config.py`.

In `multi_trip_construct`, path agreements were originally scattered across
business logic (see `2026-04-17-path-property-consolidation.md`: 20 violations
across 10 files). Once consolidated into `src/MTR/configs/path_config.py`,
the layout became refactorable, IDE-navigable, and lint-able.

The pattern is repo-agnostic — any project that writes files into a
configurable layout (data pipelines, ETL, ML training, build outputs) benefits
from the same discipline. Without a skill, agents tend to recreate inline
concatenation and re-scatter the agreement.

## Goals

- Teach agents the rule: **only the path-config module may contain path
  segment literals used to assemble paths**.
- Teach agents the structure: a tree of frozen pydantic models where
  constructor fields are runtime variables (mount roots, IDs, versions) and
  `@property` / instance methods derive fixed names.
- Teach agents the extension procedure: add the new path as `@property` (no
  parameter) or instance method (parameterised) on the appropriate class,
  reusing the nearest existing parent property; never as `@staticmethod`.
- Provide a reference implementation (the MTR `PathConfig` / `PoiPaths` /
  `ClipPaths` triple) and a violation-detection grep recipe.

## Non-Goals

- Mandating pydantic (the pattern works with `attrs`, `dataclasses`, plain
  classes — but the skill recommends pydantic v2 frozen models for parity
  with the source).
- Codifying a particular root layout (mount points, environment subpaths)
  — those are project-specific.
- Replacing `pathlib.Path`-vs-`str` or `os.path` discussions; the skill
  assumes `pathlib.Path` everywhere.

## Proposal

Create `skills/centralized-path-config/` with:

- `SKILL.md` whose `description` triggers when an agent is about to:
  - Write or edit a Python file that builds a `Path` by joining literals,
    or
  - Add a new derived path location to a project that already has a
    path-config module.
- `references/path-config-rule.md` — the prose rule (adapted from
  `multi_trip_construct/.agents/spec/no_inline_path_concatenation.md`).
- `references/path-config-template.py` — a minimal frozen-pydantic
  `PathConfig` / `<Scope>Paths` skeleton with cached factory builders
  (`@lru_cache`).
- `references/extension-decision-tree.md` — when to add a `@property`
  vs. an instance method vs. promoting an existing literal.
- `scripts/find_inline_paths.sh` — a grep recipe that flags
  `Path(...) / "literal" / "literal"` outside the allow-listed module.

The skill should explicitly cross-reference `typed-interfaces` and
`development-best-practices`.

## Alternatives Considered

| Alternative | Why Not |
|---|---|
| Combine paths + hyperparameters into one mega-config skill | Different shapes: paths are mostly `@property`s, hyperparameters carry default values, persistence, env-var loading. Merging muddies the trigger. |
| Lint-only skill (no template) | The hard part is *what to add* and *where*, not just *what to forbid*. A template is needed. |
| Project-specific skill bound to MTR | Pattern repeats across pipelines / ETL / ML; skill should be general. |

## Risks

- Risk: Agents over-apply the rule and refactor scripts/playground code that
  shouldn't be subject to the discipline. Mitigation: skill scopes to "business
  logic" and explicitly carves out playground/scratch/scripts.
- Risk: A frozen pydantic dependency is too heavy for tiny projects.
  Mitigation: template ships a stdlib-`dataclass` variant in an appendix.

## Open Questions

- OQ1: Should the skill mandate pydantic v2 specifically, recommend it, or
  stay tooling-agnostic and offer multiple templates?
- OQ2: Should the violation-detection script live in the skill, in a target
  project, or both (skill ships it, target project copies)?
- OQ3: Should the skill require a `factory` function with `@lru_cache` for
  derived path objects (`build_<scope>_paths`), or treat that as optional?
- OQ4: How do we handle generated/derived paths that depend on time
  (`datetime.now()` in `poi_archive_path`)? Allow as instance method, or
  insist on injecting the timestamp?
- OQ5: Should the skill ship a paired tool hook (Kiro / Claude Code hook /
  pre-commit) that nags on inline-concat? If yes, that pulls in the
  `agent-spec-and-tool-hook` skill (RFC-0004) — should the two skills be
  bundled or kept independent?

## Acceptance Criteria

- [ ] `skills/centralized-path-config/SKILL.md` exists with a trigger
      description matching the rule.
- [ ] References include the rule prose, a working template, and an
      extension decision tree.
- [ ] `just validate` passes after the skill is added.
- [ ] An external project (not MTR) can adopt the skill and the template
      compiles and type-checks under `uvx ty check`.

## Rollout

1. Draft skill files from this RFC after grilling resolves OQ1–OQ5.
2. Validate with `just validate`.
3. Land alongside any peer skills decided in adjacent RFCs.
4. If RFC-0004 is accepted, ship the paired hook artefact in a follow-up.
