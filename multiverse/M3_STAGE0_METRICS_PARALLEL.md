# ASCT M3 — runtime safety, extensible metrics, STEP0 band variants

## Scope and status

Implemented here:

1. `rc.useParallel=0` is honored in the two source-stage `parfor` loops,
   preventing an implicit MATLAB Processes pool in STEP8 and STEP9.
2. Paired STEP0 frequency cutoffs `mv.factors.filter.bandHz={[2 48],[8 12]}`.
   Factor choices are converted to actual ExSetup `filter.HPfreq/LPfreq`.
3. Stage0 filter validation: positive frequencies, HP below LP, positive
   FIR orders if supplied, LP below Nyquist after optional resampling.
4. Independent, post-hoc metric plugins, with optional automatic evaluation
   after the multiverse run. Per-plugin failures remain separate from stage
   status. A built-in operational metric counts output artifacts; an optional ground-truth plugin computes directed-edge F1/precision/recall/FPR for simulations with explicit ROI-aligned truth.
5. Regression tests in `tests/TestMultiverseM3.m`.

Not yet empirically validated on Fossil after this change: clean MATLAB
process exit after STEP8/9 and real STEP0 passband processing on raw EEG.
Mock tests do not substitute for these operational checks.

## Minimal deployment checks on Fossil

```bash
/opt/matlab_nogui_restricted.sh -batch "addpath(pwd); t=runtests('tests/TestMultiverseM3.m'); disp(t); assert(all([t.Passed]));"
/opt/matlab_nogui_restricted.sh -batch "addpath(pwd); t=runtests('tests'); disp(t); assert(all([t.Passed]));"
```

## Recheck original M1+M2 four-variant data WITHOUT rerunning it

```matlab
addpath(fullfile(pwd,'multiverse'));
root='/mnt/devv/Exp/LG/wprawki/flanker/ana1_mv_flanker_m1_m2_v1__multiverse';
plugins=struct('name','artifacts','fn',@asct_multiverse_metric_artifacts);
T=asct_multiverse_metrics(root,plugins);
disp(T);
assert(all(T.status=="passed"));
```

## Runtime segfault smoke check without touching existing outputs

No previous four-variant outputs should be overwritten. Start with the
new dry-run `flanker_multiverse_serial_probe_setup.m` and check the MATLAB
process exit code. Its `outputName=ana1_mv_flanker_serial_probe_v1` is
independent of previous results and it runs one participant/variant with
`rc.useParallel=0`. After reviewing the plan, set `multiverse.dryRun=false`
in a temporary copy of the script. The log must contain
`ASCT_SERIAL_PROBE_PIPELINE_PASSED`, no auto-created 32-worker pool, and
MATLAB must return exit code 0. A native BLAS/MATLAB segmentation fault,
if it persists despite no pool, requires a separate runtime investigation.

## Milestones vs original MULTIVERSE ANALYSIS list

| Original document item | Implementation status | Validation status |
|---|---|---|
| STEP0 wide vs narrow [F] | Paired-band factor in general runner; raw-to-STEP10 support | Mock tests prepared; raw EEG not yet run |
| STEP8 lambda / cov normalization | M2 | Test validation; only depth weighting run on real Flanker |
| STEP8 depth weighting | M2 | Real Flanker: 0 vs 0.5, 4/4 variants passed |
| STEP8 loc method [F*] | MNE only, other methods explicitly rejected | Deferred |
| STEP8 template vs individual T1 [F] | Template used in Flanker pilot; individual precomputed models supported | No paired real T1 multiverse test |
| STEP10 model order fixed/AIC | Implemented in earlier STEP10 | 8 Flanker variants passed; AIC ceiling 10/20 remains scientific limitation |
| STEP10 number of ROIs 5–12 | `con.chanSel` is a supported factor | Real Flanker 5 ROIs only; 5–12 not validated |
| STEP10 varNorm 0/1 | Implemented | Real Flanker 8 STEP10 variants + M1/M2 integration |
| STEP10 evoked-signal nonstationarity | `removeERP` switch implemented | No simulation validating nonstationarity effects |
| Simulations 3–10 sources, distance, interaction count/strength/lag, SNR | Existing simulation/smoke/replicate helpers in repository | Full factorial realistic simulations not yet implemented |
| Stats/performance single case [i] | Existing `asct_multiverse_score`, `evaluate_output`; extensible read-only metrics now added | Computational QA, not scientific hypothesis testing |
| Group analysis [ii] LMM | Out of first-phase scope | Deferred |

Work attributed to Mirek and Michal remains outside this milestone plan.
