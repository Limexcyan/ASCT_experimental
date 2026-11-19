# M4 — STEP0 and STEP10 validation on real Flanker EEG

## Scope and limitations

This is a **non-invasive validation scaffold**, not a full implementation merged into ASCT. It does not run or rewrite the multiverse engine. The exact current GitHub repository sources were not accessible when the package was made, so we must not guess parameter names or assume a specific STEP0 artifact layout. No MATLAB run on Fossil has been performed for this package.

The user team TODO (Mirek and Michal) is explicitly out of scope.

## What the uploaded logs establish

- Flanker example with `A1_FLA_1`, 5 ROIs, `FLANK_INCO` and `FLANK_CONG`.
- 4 M1+M2 real-data variants succeeded and 2 STEP10 variants reused STEP9 artifacts.
- M3 STEP0 wide/narrow bands and STEP10 normalization fixed/AIC and removeERP tests exist; MATLAB regression reported 84/84 passed.
- This does **not** establish a complete real-data STEP0 × STEP10 validation run.

## M4 experiment matrix (recommended)

Use a manageable **2 × 2 × 2 × 2 = 16 variants** for one EEG subject first:

| Factor | Values |
|---|---|
| STEP0 band | `wide`, `narrow` (use the repository's existing exact frequency definitions) |
| STEP10 `varNorm` | `0`, `1` |
| STEP10 order | `fixed`, `AIC` |
| STEP10 `removeERP` | `0`, `1` |

Keep ROI definitions, dataset, localization, and other factors constant. If a full grid is too expensive, run 2 bands × 2 `varNorm` = 4 first, then expand to 16. Never treat test fixtures as real Flanker results.

## Preflight on Fossil

```bash
cd ~/ASCT_experimental
git switch feature/multiverse_analysis
git pull --ff-only origin feature/multiverse_analysis
git rev-parse HEAD
git status --short
ls flanker_multiverse_step0_bands_setup.m flanker_multiverse_m1_m2_setup.m
/opt/matlab_nogui_restricted.sh -batch "addpath(genpath(pwd)); t=runtests('tests'); disp(t); assert(all([t.Passed]));"
```

Read both setup scripts and `multiverse/M3_STAGE0_METRICS_PARALLEL.md` to confirm current `multiverse.grid`, `dryRun`, the dataset input root, real band definitions and exact connectivity parameter names. Create a **separate copied setup** for M4; **do not** edit the tracked setup or legacy ASCT pipeline. Use `dryRun=true` first. Inspect the plan and verify STEP0 is reexecuted when bands change, and STEP10-only changes reuse STEP9 only if compatible.

Next run that copied setup with `dryRun=false` (one subject, safely limited workers). Capture full MATLAB stdout/stderr, process exit code and final manifest. If the process exits with a segmentation fault despite successful saved results, mark as a runtime issue—not full pass.

## Audit saved outputs

Place `m4_audit.m` and `run_m4_fossil.sh` together, then:

```bash
./run_m4_fossil.sh ~/ASCT_experimental \
  /mnt/devv/Exp/LG/wprawki/flanker/NAME_OF_EXPERIMENT__multiverse 16
```

This validates manifest row count, unique variant names, success status, analysis directory existence and `.mat` file counts below `8_CONN`, writing `m4_audit_summary.csv`.

**Important:** STEP0 artifact provenance is *not* verified by the standalone auditor; it always reports `step0Verified=false`. It must be checked against the current pipeline's configured directories. The auditor cannot confirm actual numeric effects in NDTF matrices, the matching of parameter values to outputs, signal quality, or valid MVAR model estimates. Do not publish the audit as end-to-end scientific validation.

## M4 acceptance criteria before declaring complete

1. All 16 configurations show the intended parameter values in their reproducible config and manifest, with unique run identifiers.
2. Both bands have documented effective filter settings and distinct, correctly sourced STEP0 artifacts. Check sample frequency and passband and prevent cross-band cache reuse.
3. Every real-data run exits 0, all variants are marked successful, and all expected DC/condition STEP10 outputs exist and are readable.
4. Fixed vs AIC model order, normalization and ERP removal are verified in generated model metadata (not merely in plan labels).
5. Numerical comparisons are recorded for matched one-factor pairs; check output finiteness, nontrivial differences where theoretically expected, and reproducibility on rerun.
6. Rerun with resume should skip completed compatible computations but not mix artifacts across changed upstream settings.
7. Provide machine-readable summary, command log, Git commit SHA and human-readable report documenting issues.

## Hand-off explanation for original ASCT author

The multiverse is an experiment orchestration layer wrapping *unchanged scientific steps* of ASCT. A grid assigns parameter sets, a dependency plan selects the earliest affected step, cache/reuse avoids repeating compatible upstream computations, and each output is segregated by variant and recorded in a manifest. Different preprocessing bands invalidate all downstream computations; a changed connectivity-only setting can reuse the earlier reconstructed ROI signals.
