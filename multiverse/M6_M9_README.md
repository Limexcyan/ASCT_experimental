# M6-M9: simulation, localization, MVAR and single-case sensitivity

These modules extend the existing `multiverse/` functions. They do not change
`sc_initAnalysis`, existing M1-M4 manifests, or colleagues' TODOs. The M6-M9
base patch changes the STEP10 label-file path in `sc_8_CONN.m` for selected
ROI subsets; the original ASCT runner remains authoritative for real data.
The refinement patch changes only simulation/statistics helpers and tests.

## Scope and interpretation

| Area | Implemented | Not claimed |
|---|---|---|
| M6 | Known directed VAR `trueA(target,source,lag)`, 3-10 source scenarios, 1.5/6 cm spacing, number of edges, coupling, lag, SNR; distance-aware synthetic sensor mixing; paired oracle and inverse-proxy recovery (including per-seed F1 differences) | Biophysical head model or true source-localization accuracy |
| M7 | Paired grid of lambda / normalization / depth weighting, simple regularized synthetic inverse, MNE STEP8 factor helper that avoids inert lambda combinations in cov mode | Synthetic proxy `norm='cov'` is not FieldTrip's `loc.norm='cov'` implementation |
| M8 | Fixed/AIC, 5/8/12 ROI synthetic signals, varNorm 0/1, ERP present/removed, innovation variance drift, fitted VAR diagnostics; read-only real STEP9 ROI preflight and real STEP10 factor helper | Verification of the external `multar1m` binary or 12 actual Flanker ROI signals |
| M9 | Directed precision/recall/F1/FPR, coefficient lag and strength MAE, VAR stability, residual lag-1 and variance-ratio screens, independent-case bootstrap CIs, paired ERP effects and within-case analytical robustness | Formal nonstationarity or residual whiteness significance tests; group-level inference from one subject |

Only these source-local tests use `asct_mvar_fit`, `asct_mvar_aic`,
`asct_mvar_dtf` and `asct_multiverse_score`. **They do not invoke `multar1m`**.
The simulator also supports nSources=11..12 for the separate M8 experiment;
M6 study scenarios explicitly reject nSources > 10.

Truth adjacency uses `[target, source]`; a known link at lag `ell` is the
nonzero off-diagonal element in `trueA(:,:,ell)`. All generating graphs are
acyclic, with a shared anchor edge (source 1 to target 2) when interactions
are nonzero. This keeps the endogenous VAR stable and gives every nested
ROI set at least one known interaction. For zero-edge controls, recall/F1
are undefined (NaN), and FPR is the appropriate detection metric.
ERP is deliberately added after VAR generation: ground truth is the
underlying *endogenous* graph, and phase-locked ERP is a possible confound.
`varianceDrift` changes the innovation scale across time; ERP subtraction
cannot remove that separate form of nonstationarity. The M6 generator skips
zero VAR-lag matrices and batches sensor projection across trials; neither
change alters the causal graph or the intended measurement model.

The spatial inverse is explicitly a **synthetic diagnostic proxy**. The
`cov` proxy uses known synthetic sensor noise variance as ridge regularization;
the real ASCT `cov` mode computes per-component SNR and calls FieldTrip.
Never cite proxy comparisons as evidence of actual covariance-based MNE
localization performance.

Normalization in `asct_m8_fit` uses one global standard deviation per ROI.
Its fitted VAR coefficient matrix `A` is returned in the original ROI units
for strength/lag errors. The additional `Adtf` coefficients reflect the
analyzed scale for DTF (and thus reflect varNorm differences). This need not
match the exact normalization used by external `multar1m`.

## MATLAB tests (after the current real-data M4 run has finished)

```matlab
addpath(pwd);
addpath(fullfile(pwd,'multiverse'));
t = runtests({'tests/TestMultiverseM6.m', ...
              'tests/TestMultiverseM7.m', ...
              'tests/TestMultiverseM8.m', ...
              'tests/TestMultiverseM9.m'});
disp(t);
assert(all([t.Passed]));
```

### Standalone simulation studies (create NEW output folders)

For a systematic M6 factorial rather than the six default exploratory
scenarios, use `asct_m6_factorial` with an explicit budget:

```matlab
f = struct('nSources',[3 5 10],'distanceCm',[1.5 6], ...
    'nInteractions',[1 2],'strength',[0.2 0.4], ...
    'lag',[1 2],'snrDb',[0 15]);
scenarios = asct_m6_factorial(f,256);  % 96 configurations
opts6.scenarios = scenarios;
opts6.nReplicates = 30;
opts6.nBootstrap = 2000;
% [cases,summary] = asct_m6_study('new_output_folder',opts6);
```

The study aborts before execution if the unpruned factor grid exceeds the
budget or the destination output folder exists. Factorial inference still
requires explicit multiplicity decisions.


```matlab
addpath(fullfile(pwd,'multiverse'));

% M6: six distinct source/sensor scenarios, each with independent seeds.
[simulationCases,simulationSummary] = asct_m6_study( ...
    fullfile(pwd,'..','m6_study_01'));

% M7: lambda and depth interactions in a synthetic inverse proxy.
[localizationCases,localizationSummary] = asct_m7_study( ...
    fullfile(pwd,'..','m7_proxy_study_01'));

% M8 and M9: paired ERP / stationary-vs-drifting noise / ROI / MVAR grid.
[connectivityCases,connectivitySummary,pairedERP] = asct_m8_study( ...
    fullfile(pwd,'..','m8_m9_study_01'));
```

By default these are **small exploratory designs** (five independent
realizations per group), not publication-grade confidence intervals. Increase
`opts.nReplicates` substantially (e.g. >=30 or a prespecified power target),
retain paired seeds, document multiplicity and inspect result quality before
interpreting CI limits. `opts.nBootstrap` controls resampling of **independent
realizations** only, never trials, windows or frequency bins as independent
samples. M9 rejects duplicate simulation seeds within a bootstrap group
rather than silently counting reused observations as independent replicates.
Typed table grouping keeps `NaN` lambda levels together across MATLAB
releases, and batched bootstrap sampling limits temporary memory use.
Factor-level summaries retain `nValid_*` for metrics such as F1 that can be
undefined in zero-edge controls; FPR remains meaningful in those controls.
All studies fail on an existing output directory rather than overwrite.

Outputs:

* M6: `m6_cases.csv`, `m6_summary.csv`, `m6_results.mat` (includes trueA, truth,
  source/sensor positions and mixing for each realization).
* M7: `m7_cases.csv`, `m7_summary.csv`, `m7_results.mat`.
* M8: `m8_cases.csv`, `m8_summary.csv`, `m8_results.mat`.
* M9: `m9_erp_pairs.csv`, `m9_erp_effect_summary.csv`,
  `m9_robustness_cases.csv`, `m9_robustness_summary.csv` within M8 output.

The scripts do not touch the existing real-data multiverse manifests, model
folders or M4 results.

## Real ASCT M7 factor grid (planning only)

After loading an ordinary ASCT `setup` struct and `mv` settings:

```matlab
[factors,includeFcn,nRuns] = asct_m7_realdata_factors( ...
    setup.loc,[0.05 0.1],[0 0.5]);
mv.factors = struct('loc',factors);
mv.includeFcn = includeFcn;
mv.maxRuns = nRuns;
mv.cacheStages = true;
mv.dryRun = true;
mv.strictLocalization = true;
mv.sourceAnalysis = 'ana1';
mv.outputName = 'm7_loc_v1';  % choose a NEW result name
[plan,specs] = asct_multiverse_plan(setup,mv);
```

This uses the existing STEP8 parameter keys. In `cov` mode the baseline
lambda is retained but not swept, since it has no direct effect. The plan is
not evidence that a FieldTrip localization has succeeded. Actual runs require
all M2 input artifacts and strict localization preflight.

## Real ASCT M8 STEP10 grid (planning only)

```matlab
% Existing Flanker currently defines five anatomical ROI names.
[factors,nRequired] = asct_m8_realdata_factors(setup,5);
% Read every saved STEP9 file; must be done once that analysis has finished.
roiReport = asct_m8_realdata_preflight(setup,'ana1',nRequired);
mv.factors = struct('con',factors);
mv.maxRuns = 8;
mv.sourceAnalysis = 'ana1';
mv.outputName = 'm8_conn_five_roi_v1';
mv.dryRun = true;
[plan,specs] = asct_multiverse_plan(setup,mv);
```

For 5/8/12 ROI comparisons, **first** create and validate at least 12 real
ROI waveforms for each participant/condition/modality using real STEP9.
Then use `asct_m8_realdata_factors(setup,[5 8 12])`, run the same full-file
preflight with `nRequired=12`, and set `mv.maxRuns=24`. Adding a `chanSel`
choice does not reconstruct missing ROIs. Source-ICA rejection can also
prevent a 12-ROI reconstruction.

The M8 patch makes `sc_8_CONN.m` set `mv.descfil` to `labels_trimmed.txt`
when a subset was selected. This is a small production STEP10 change and must
be regression-tested against the external `multar1m` implementation before
merging into a real analysis branch. Use the read-only
`asct_m8_conn_audit(multiverseRoot)` after processing; it checks effective
output dimensions, saved order, `varNorm`, VAR spectral radius, residual
covariance and selected label-file count. It does **not** infer ground truth
from real EEG or silently accept unstable MVAR as scientifically valid.

## Interpreting M9

* **False positives** are directed connections outside the known synthetic
  graph; FPR uses directed off-diagonal true negatives.
* Lag MAE is the difference between the coefficient's strongest off-diagonal
  estimated lag and its true lag, evaluated on **all** true edges regardless of
  binary DTF detection. Strength MAE compares absolute VAR coefficients in
  original physical units, not DTF amplitude.
* `spectralRadius < 1` is necessary for stability of the estimated VAR.
* Lag-1 residual correlation and half-epoch variance ratios are descriptive
  screens; they do **not** establish full stationarity/whiteness.
* `fprReduction = FPR(ERP kept) - FPR(ERP removed)` and
  `f1Gain = F1(ERP removed) - F1(ERP kept)` are paired within the same seed.
* `f1Range = max(F1) - min(F1)` across analytic decisions in a synthetic case
  summarizes the fragility of that case's conclusion. Its CI is bootstrapped
  over independent simulation replicates, not over analytic settings.
* Comparing 5 vs 12 ROI changes the network and denominator; compare aligned
  edges if matrix-level comparisons are needed, or use appropriately
  conditioned group summaries.

## Remaining scientific gates

1. Run all MATLAB tests in an isolated checkout and review failures.
2. Run independent M6/M7/M8 studies with enough replicate seeds; examine
   plots and failure cases rather than judging solely from summary means.
3. Validate real MNE STEP8 separately using FieldTrip and inspect the
   covariance-based normalization and rank of the source model.
4. Generate 12 anatomically justified real ROI signals, check ICA brain
   components and external multar label mapping.
5. Independently check `multar1m` fixed/AIC/order, normalization, stable VAR,
   lag residual diagnostics and ERP subtraction on selected real recordings.
6. Do not merge into the running M4 branch until the current job finishes.
