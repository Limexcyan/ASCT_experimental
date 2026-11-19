# M1 — Dependency-aware, resumable multiverse engine

## Scope

This is an **infrastructure** milestone. It runs real ASCT stages and records
provenance; it does not establish any scientific hypothesis, MVAR adequacy,
statistical significance, or correctness of connectivity on ground truth.

Existing entry point `asct_multiverse_realdata(setup,mv,runnerFcn)` remains
supported. In particular, `cacheStages=false` and `resume=false` by default,
so the previously validated Flanker STEP10 scripts retain their semantics.

## Interfaces

| Function | Purpose |
| --- | --- |
| `asct_multiverse_realdata_grid(mv)` | Deterministic Cartesian grid; optional includeFcn |
| `asct_multiverse_dependencies(changes)` | Earliest affected stage, dependency graph |
| `asct_multiverse_plan(setup,mv)` | Read-only stage/reuse plan, no filesystem writes |
| `asct_multiverse_realdata(setup,mv,runnerFcn)` | Execute/checkpoint the plan |
| `asct_multiverse_resume(setup,mv,runnerFcn)` | Explicit resume wrapper |
| `asct_multiverse_collect(multiverseFolder)` | Read execution results, manifest and provenance |

The real-data engine works on ExSetup `rc/chan/filter/seg/ar/ica/loc/con/design`.
It reuses the existing `asct_multiverse_realdata_prepare` and
`asct_multiverse_execute` adapters instead of introducing a second pipeline.

### Dependency stages

- `filter.*` -> STEP0, then downstream stages.
- `loc.*` -> STEP8, then reconstruction and connectivity.
- `con.decimate`, `con.lc`, `con.unc` -> STEP9, then connectivity. These
  fields alter reconstruction outputs and **cannot** safely reuse STEP9 ROI
  signals across different values.
- Other currently allowed `con.*` -> STEP10; optional STEP11 follows.
- `mv.runStatistics` runs STEP11 separately. Its settings are not STEP10 factors.

`cacheStages=true` enables cross-variant reuse **within one execution**:

- STEP9 ROI signals are reused for a STEP10-only recomputation when identical
  `filter`, `loc`, and reconstruction dependencies are present.
- STEP8 `icloc` is reused for STEP9 when the required ICA2 source also exists.
- STEP0 `6_ICA2` is reused for STEP8 when the corresponding preprocessing
  configuration is identical.

Actual reuse requires a previous **passed** donor and matching physical output
files. The manifest records `executionStartStep`, `reuseStage`, `reusedFrom`,
`attempt`, and the requested `startStep`. A dry run describes **proposed**
reuse; execution falls back to the original earliest necessary stage when
cache artifacts are absent. No stage cache is trusted on directory existence
alone. The sourceAnalysis folder is considered the already-validated baseline
of the supplied setup; do not point it to a mismatched preprocessing history.

The STEP9 path can now use `rc.iclocName` for ICLOC and `rc.ica2Name` for ICA2
independently. That small change in `pipelineSC/sc_7_SIG_RECON.m` is necessary
for valid reuse of STEP8 localization outputs.

### Example: STEP8 + STEP10

```matlab
mv.sourceAnalysis='ana1';
mv.outputName='ana1_mv_loc_conn_m1';
mv.maxRuns=16;
mv.dryRun=true;
mv.cacheStages=true;
mv.runStatistics=false;
mv.factors.loc.norm={'lambda','cov'};
mv.factors.con.varNorm=[0 1];

[plan,specs]=asct_multiverse_plan(setup,mv); % no writes
results=asct_multiverse_realdata(setup,mv); % dry run writes plan checkpoint

% After reviewing all inputs and the plan, change dryRun to false.
% results=asct_multiverse_realdata(setup,mv);
```

This example requires real baseline `6_ICA2` from `sourceAnalysis` and all
usual ASCT/FieldTrip dependencies. Unsupported localization methods still
raise an error; the M1 runner does not make them available.

### Sparse/non-Cartesian grid

```matlab
mv.factors.con.varNorm=[0 1];
mv.factors.con.removeERP=[false true];
mv.includeFcn=@(changes) changes.con.varNorm==double(changes.con.removeERP);
```

The predicate returns a logical scalar; original deterministic config IDs are
retained even when some combinations are removed. Grid expansion is capped at
100,000 pre-filter combinations and filtered count must not exceed maxRuns.

### Resume without deleting/overwriting data

```matlab
mv.resume=true;
mv.dryRun=false;
results=asct_multiverse_resume(setup,mv);
```

`resume=true` requires an unchanged frozen execution plan (`planSnapshot` in
`realdata_results.mat`). Previously passed variants are skipped. If a variant
folder exists but the variant was not completed, execution **stops without
modifying that folder** until `mv.retryFailed=true` is explicitly specified.
With that flag, the incomplete folder is moved to
`<analysis>.incomplete_backup_0001` (or the next unused suffix), never deleted;
then a new variant attempt runs. Already-completed STEP10 is not recomputed
when only STEP11 failed: with explicit `retryFailed=true`, the runner checks
STEP10 files before retrying statistics. This can overwrite partial STEP11
outputs from a previous failed attempt; inspect them before enabling retry. If a previous plan differs, use a new outputName, never change the
same output in place.

Checkpoint files are updated by writing temporary files and renaming them:

- `<output>__multiverse/realdata_results.mat` — authoritative checkpoint with
  results, full `planSnapshot`, original factor specs, settings and statuses.
- `<output>__multiverse/realdata_manifest.csv` — human-readable projection,
  including Git commit/dirty status if a Git checkout is available.
- `<output>__multiverse/realdata_events.csv` — append-only operational events
  (START, REUSE, PASS, FAIL, ARCHIVE, SKIP).
- `<output>__mv_NNNN/multiverse_setup.mat` — exact effective runsetup and spec.

The checkpoint is written **before the first stage** and after each execution
transition, so a crashed process does not leave blank, unidentifiable rows.
The Git revision and dirty status are also frozen in the resume identity;
changing the code checkout refuses automatic resumption unless a fresh
outputName is used. In non-Git deployment the code identity is `unknown`; set
`mv.codeVersion` explicitly to track a release identifier.

If an old, pre-M1 manifest lacks a matching checkpoint, the runner refuses
resume. Use the existing separate `flanker_step10_audit(...,true,true)` recovery
mode for historical completed outputs; it validates files but cannot invent
an execution history.

`mv.allowOverwrite=true` is an existing legacy option, not recommended for
reproducible studies. It cannot be combined with `resume=true`.

### Testing and deployment

```bash
/opt/matlab_nogui_restricted.sh -batch \
  "addpath(pwd); t=runtests('tests'); disp(t); assert(all([t.Passed]));"
```

`tests/TestMultiverseM1.m` uses lightweight fake filesystem outputs to test
stage graph, dry planning, caching/fallback, includeFcn, non-destructive
resume, backup-on-retry and immutable-plan checks. These tests do **not**
replace an ASCT/FieldTrip integration test with real stage 8/9 data.

Do not enable `cacheStages=true` on a valuable real study before a separate
small STEP8+STEP10 integration trial and inspection of its input files.
