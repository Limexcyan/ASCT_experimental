# ASCT multiverse analysis — single-case / simulation phase

This module is **MATLAB**, not the older standalone Python prototype. It is built
against `sc_initAnalysis.m`, `pipelineSC/sc_8_CONN.m`, `MNE_functions/sc_sourceLocalize.m`
and `external/mmultar` from this ASCT checkout.

## Implemented, and what is not implemented

| Domain | Factors | Execution |
|---|---|---|
| SIMULATION | 3–10 sources, 1.5 vs 6 cm between adjacent interacting nodes, 0..N-1 directed interactions, strength, lag, sensor/ROI SNR, evoked waveform amplitude | MATLAB source-level stable VAR simulation and synthetic leadfield; **not** a realistic MEG/EEG/ICA simulation |
| STEP0 | broad [1,45] or narrow [8,12] Hz | `filter.HPfreq`, `filter.LPfreq` in actual ASCT; ideal FFT filter only in oracle-source benchmark |
| STEP8 | `loc.norm` lambda/cov, `loc.lambda`, `loc.depthWeight`, `loc.method=mne` | actual FieldTrip path when full ASCT adapter runs; non-MNE methods deliberately rejected until configured |
| STEP10 | `con.mvarOrd` fixed/AIC, `con.chanSel` first 5–12 ROI, `con.varNorm`, ERP subtraction | actual `sc_8_CONN` + multar integration, AIC headless; ERP correction of input `mltin` before fitting |
| STATS | F1/precision/recall/FPR versus known directed edges, bootstrap F1 CI, saved multar `NDTF` evaluation | single-case only; **no** group mixed models |

**Not implemented:** template vs individual T1 switching (needs a compatible FieldTrip head/source model), arbitrary source-to-sensor realistic forward models, fully automated ICA/source-localization ground-truth mapping, interaction-generation models beyond a directed chain, non-MNE inverse methods, real-data non-stationarity validation. Do not treat a good oracle-source F1 as evidence of successful ASCT localization.

The proximity simulation puts adjacent interacting sources on a 1.5 cm-spaced line; the distant variant uses 6 cm. Thus `nInteractions <= nSources-1`. This is an intentionally simple **controlled** ground truth, not a biophysically plausible spatial network. `nROIs` is a separate analytical dimension, but oracle benchmark operates only on `nSources`: localization/ROI factors have **no impact** there.

## 1. Source-level benchmark (runs without FieldTrip/ICA)

```matlab
root = pwd;                 % ASCT checkout root
addpath(fullfile(root,'multiverse'));
results = asct_multiverse_source_demo(fullfile(tempdir,'asct_oracle_demo'));
results(1).metrics            % f1, estimatedOrder, bootstrapF1CI etc.
```

The oracle benchmark is the minimal reproducible study: simulated ROI/source series ->
frequency selection -> optional trial-mean ERP subtraction -> pooled-trial OLS MVAR
-> frequency-resolved row-normalized directed transfer function -> F1 versus known
adjacency. Its 95% F1 CI resamples **whole trials**, not time points. It is a
reference analysis, **not** the source localization stage or multar computation.

## 2. Integrate with ASCT itself (your ExSetup/data are required)

Supply an existing ASCT ExSetup as `p` with fields:
`rc`, `chan`, `filter`, `seg`, `ar`, `ica`, `loc`, `con`, `design`
(optionally `simul`, `begId`, `endId`). This adapter must also prepare an actual
ASCT-readable dataset if you want to use newly generated synthetic sensors.
`sc_preproc_meg_itab` currently has an existing hard-coded simulation template
recording path, so the synthetic `sensors` cube cannot be passed as a MAT file
and expected to run the real pipeline without a custom import/forward-model
adapter.

```matlab
addpath(fullfile(pwd,'multiverse'));
study = asct_multiverse_defaults();
study.maxRuns = 16;
% ExSetup is the experiment-specific function that returns the full setup struct.
% setupFcn receives (config,simulatedSignals).
setupFcn = @(cfg, sim) my_experiment_setup(cfg, sim);
results = asct_multiverse_run(study,setupFcn,fullfile(tempdir,'asct_multiverse'));
```

ASCT execution sets its own `rc.analysisFolder` and uses distinct
`rc.analysisName + '__' + config.id`, so intermediate artifacts cannot silently
be reused. Because **STEP0** changes, each specification starts at `rc.load=0`
and stops after connectivity (`rc.stop=10`). This can be very costly for a large
factor grid; use `maxRuns` intentionally. Existing installed FieldTrip and
multar dependencies are still required; this module does not bundle them.

With `study.useMultarBootstrap=true` and experiment-specific multar `bootnum`
settings, the `sc_8_CONN` simulation-statistics code path can be enabled. The
`_stat_mltin` filename typo was corrected; this path still requires validation
against real installed mmultar and should not be considered CI-verified.

### Ground-truth evaluation of actual multar outputs

`asct_multiverse_execute` will add `output.performance` automatically **only
if** `p.truthConnectivity` is explicitly supplied. It must be an ROI-aligned
binary matrix `truth(target,source)`, matching the selection/order of `con.chanSel`.
Without it, ground-truth F1 cannot be computed correctly. To score an existing
run directly:

```matlab
stats = asct_multiverse_evaluate_output(analysisFolder, conName, truthROI);
```

The point estimate uses NDTF across saved frequencies, row/target x
column/source. `NDTF_boot` is detected when present but full confidence band
aggregation across frequencies is not yet applied to the point F1 calculation.

## Paired design and safeguards

`asct_multiverse_grid` samples a few **simulation scenarios** and crosses them
with the same sampled **analysis pathways**. The simulation seed is computed from
simulation-factor values only, so signal realization is exactly identical
across alternative filtering/localization/connectivity choices. `rng` state is
restored after generating the grid and simulations. Do not interpret the sample
as an exhaustive search; store the selected configuration manifest.

- `multiverse_manifest.csv` — IDs, simulation index, analysis index, seed, status/error.
- `multiverse_results.mat` — complete configuration parameters and runner outputs.
- `<config.id>.mat` — per-configuration result; failures isolated and recorded.

## Testing

```matlab
addpath(pwd);
results = runtests('tests');
assert(all([results.Passed]));
```

GitHub Actions already has `.github/workflows/matlab-tests.yml` on the `main`
branch, running MATLAB tests on pushes to main, PRs, and manual dispatch. The
new `tests/TestMultiverse.m` is discovered by that workflow. Test results now
upload as a JUnit artifact. Passing these unit tests confirms the source-level
reference/MATLAB API mapping only — not an end-to-end ASCT run with FieldTrip,
ICA, a participant MRI, or real multar. The latter needs a dedicated fixture
and a separate integration workflow.

### Optional simulated sensor export (ITAB-style)

`asct_multiverse_export_itab_sim(sim.sensors, folder, baseName)` creates a
`*_sim.mat` file containing ASCT's expected 2-D `sim` matrix. This **does not**
make the generated random leadfield biologically meaningful. For `syn-sim` or
`itab-sim`, set `rc.simTemplateDataset` to a real sensor/header recording, and
match its channel ordering/count **and sampling rate**. `sc_preproc_meg_itab`
now sets `cfg.dataset` to that template before calling FieldTrip; otherwise an
explicit `ASCT:MissingSimTemplate` is raised if the old legacy template path
is not present. Simulation results using a random mixing matrix must not be
interpreted as valid MNE localization performance.

## 0. Two-trial / two-pathway smoke test for the feature branch

For the first remote-server check, run this **without raw MEG data or a T1**.
It uses *one* synthetic three-source scenario with **exactly two time-series
trials** (`study.simulation.nTrials=2`), processed through **two paired
analytical specifications**: wide `[1 45] Hz` and narrow `[8 12] Hz`.
The fixed MVAR order is 2. No bootstrap is requested for a two-trial smoke.

From the ASCT checkout root:

```bash
matlab -batch "addpath('multiverse'); asct_multiverse_smoke('multiverse_smoke_results');"
```

For interactive MATLAB:

```matlab
addpath(fullfile(pwd,'multiverse'));
results = asct_multiverse_smoke(fullfile(pwd,'multiverse_smoke_results'));
assert(numel(results)==2 && all(strcmp({results.status},'passed')));
```

Outputs in `multiverse_smoke_results/`:

- `multiverse_manifest.csv` — two paired configurations, shared simulation seed, pass/fail status.
- `smoke_metrics.csv` — `configuration,bandMode,nTrials,estimatedOrder,f1,precision,recall`.
- `multiverse_results.mat`, `smoke_settings.mat`, plus a `.mat` for each configuration.

The mock **does** generate VAR source signals, apply the analytic-band choice,
fit MVAR, and estimate a reference directed transfer function. It **does not**
execute the production `sc_8_CONN`, `mmultar`, ICA or FieldTrip localization;
`nROIs`/localization settings are mapped but do not influence these oracle
scores. Successful results mean the branch infrastructure and paired design
work; they do **not** demonstrate realistic MEG source localization accuracy.

The `.github/workflows/matlab-tests.yml` workflow is configured to run on
pushes to `feature/multiverse_analysis` (as well as `main`) and on pull requests.
It runs both the MATLAB test suite and this smoke, then uploads its CSV/MAT
files as a GitHub Actions artifact.

## 3. Twenty independent simulations, two trials each (paired benchmark)

The first `asct_multiverse_smoke` compares just ONE simulated realization and
cannot establish a band effect. For a reproducible follow-up of 20 independent
realizations with the **same 2 trials per realization**, run:

```bash
/opt/matlab_nogui_restricted.sh -batch "addpath('multiverse'); asct_multiverse_replicates('multiverse_replicates_results',20,2000);"
```

`asct_multiverse_replicates` regenerates a new source-level VAR simulation for
*each* replicate (distinct RNG seed); both wide and narrow processing reuse
exactly the same observed source data within the replicate. Replicate #1 uses
the same seed as the original 2-trial smoke for direct comparison. It exports:

- `replicate_metrics.csv`: each replicate/pathway with TP/FP/FN/TN, F1,
  precision, recall, false positive rate, order, number of trials and seed.
- `paired_f1.csv`: wide, narrow and wide-minus-narrow F1 side by side.
- `paired_summary.csv`: mean F1 per band, mean paired difference and
  percentile 95% confidence intervals for simulation-to-simulation variation.
- `paired_results.mat`: study settings, configurations, per-path metrics and
  paired summary, for later reanalysis.

**Uncertainty unit:** bootstrap resamples *independent simulations* as complete
pairs, **never** individual samples or the two data trials as if independent.
CI is descriptive; 20 draws may still yield imprecise estimates. Both bands use
one fixed 0.15 DTF threshold and the same ground-truth directed source network.
No multiple-comparison correction, realistic MEG mixing/inversion, or
production `mmultar` claim is made here.
