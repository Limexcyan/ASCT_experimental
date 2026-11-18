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

## Real experimental data: launch directly from an existing EX_SETUP file

This is the preferred interface for researchers accustomed to the singleverse
EX_SETUP script. It **does not synthesize any signals** and does **not** use
F1 against imaginary ground truth. The `multiverse.mode='single'` branch
continues to call the original `sc_initAnalysis` unchanged.

A working example is included in `templates/EX_SETUP_multiverse_template.m`. In your
existing experiment setup, keep all your original settings and paths.
Add near the top, after `rc.load`/`rc.stop`:

```matlab
multiverse.mode = 'multi';              % or 'single'
multiverse.sourceAnalysis = 'ana1';      % completed singleverse folder
multiverse.dryRun = true;               % START with a dry run
multiverse.maxRuns = 2;
multiverse.factors.con.varNorm = [0 1]; % precisely two STEP10 analyses
```

Replace only the final call (`sc_initAnalysis`) with:

```matlab
if strcmpi(multiverse.mode,'single')
    sc_initAnalysis
else
    toolboxRoot=fileparts(which('sc_initAnalysis'));
    addpath(fullfile(toolboxRoot,'multiverse'));
    setup=struct('rc',rc,'chan',chan,'filter',filter,'seg',seg, ...
                 'ar',ar,'ica',ica,'loc',loc,'con',con,'design',design);
    if exist('begId','var'), setup.begId=begId; end
    if exist('endId','var'), setup.endId=endId; end
    results=asct_multiverse_realdata(setup,multiverse);
end
```

After the dry run, inspect `<rc.expFolder>/<rc.analysisName>__multiverse/realdata_manifest.csv`,
then set `multiverse.dryRun=false` and run the same setup script once more.
The two outputs will be in separate `rc.expFolder` directories
`<rc.analysisName>__mv_0001` and `<rc.analysisName>__mv_0002`.
The original `<sourceAnalysis>` folder is **never overwritten**. The runner
refuses to overwrite an already existing variant output unless you explicitly
set `multiverse.allowOverwrite=true` (not recommended for initial tests).

### Run STEP11 automatically after each real-data STEP10 (experimental)

Following successful separate STEP10 and STEP11 tests on Flanker, the runner
can now execute both stages and record **independent statuses** in the
`realdata_manifest.csv` columns `connectivityStatus` and `statisticsStatus`.
It validates that the required `*_mltout.mat` files exist before STEP11 and
initializes FieldTrip when needed.

Do **not** reuse a prior output prefix unless you intentionally want to
replace its contents. For a clean end-to-end test without touching either
`ana1` or old `ana1__mv_*` directories, add to the **multiverse** block:

```matlab
multiverse.mode = 'multi';
multiverse.sourceAnalysis = 'ana1';
multiverse.outputName = 'ana1_auto_alpha'; % new, isolated output prefix
multiverse.runStatistics = true;
multiverse.dryRun = true;            % verify the plan first; then false
multiverse.maxRuns = 2;
multiverse.allowOverwrite = false;  % do not delete/rerun existing variants
multiverse.factors.con.varNorm = [0 1];
multiverse.fieldtripPath = '/opt/MATbox/fieldtrip';  % FOSSIL only
multiverse.statistics.freqRange = {[8 12]};
multiverse.statistics.subTitle = {'alpha'};
multiverse.statistics.pThresh = {0.05};
```

These `multiverse.statistics` settings override the original singleverse
`con` settings for STEP11 **only**. They do not change the statistical design
or the input to STEP10. If omitted, STEP11 uses the normal `con` settings
from the setup (potentially many contrasts, bands, and p-value thresholds).

Do not set `rc.analysisName` to the new prefix: `outputName` is applied only
in multiverse mode, preserving the familiar singleverse setup. The new
outputs go to `ana1_auto_alpha__mv_0001`, `ana1_auto_alpha__mv_0002`, and
`ana1_auto_alpha__multiverse`. Existing source and variant outputs remain
untouched. Existing variants from earlier manual STEP11 tests are **not**
resumed by this version; choose a fresh output prefix. An interrupted run
must be inspected before any manual rerun. The `allowOverwrite` option from
previous versions remains available but is not recommended.

This checks technical completion, **not** statistical reliability or
multiverse robustness. Do not interpret p-values from a four-subject pilot
as evidence of scientifically reliable group effects. Trial counts shown as
`NaN` in `AR_summary.csv` may reflect diagnostic code reading the new
analysis's empty `7_SOURCEACT`; the upstream files in `sourceAnalysis` have
trials. This diagnostic issue is separate from the successful MVAR fits.

Choose other factors using **existing ExSetup names**:

```matlab
multiverse.factors.con.mvarOrd = [5 7];
multiverse.factors.con.chanSel = {'1-3','1-5'};
multiverse.factors.con.removeERP = [false true];
multiverse.factors.con.orderSelection = {'fixed','aic'};
multiverse.factors.loc.depthWeight = [0.2 0.5];
multiverse.factors.filter.HPfreq = [1 8];
```

**All combinations are enumerated**, not sampled. If the grid has more than
`maxRuns` combinations, the runner stops before doing anything. Start with
one varied factor. Distinct variants get isolated output folders and a
machine-readable manifest with the exact settings, start stage, status and error.

### Automatic reuse policy (essential to valid comparisons)

| Varied factors | ASCT stages run | Required completed input |
|---|---|---|
| `con.mvarOrd`, `con.varNorm`, `con.chanSel`, `con.removeERP`, etc. | STEP10 | `sourceAnalysis/7_SOURCEACT` (ROI signals) |
| `con.decimate` | STEP9–10 | `sourceAnalysis/6_ICA2`, `sourceAnalysis/7_SOURCEACT/icloc` |
| `loc.depthWeight`, `loc.norm`, etc. | STEP8–10 | `sourceAnalysis/6_ICA2` |
| `filter.HPfreq`, `filter.LPfreq`, etc. | STEP0–10 | raw recordings in `rc.dataRawFolder` |

When changing localization, the runner reuses the original ICA2 but computes
**new** source localization and ROI reconstructions for every variant.
When changing filtering, it runs the whole pipeline from raw files;
never just alters `filter.HPfreq` while reusing incompatible ROI signals.
The `rc.sigroiName` lookup in `sc_8_CONN` and baseline ICA2 lookup in
`sc_7_SIG_RECON` were adjusted to support this without duplicating folders.

This is **not** a group-level inference workflow and does not calculate a
scientific performance score without known ground truth. A successful run
indicates ASCT completed; compare DTF and other connectivity results using
appropriate real-data stability/effect metrics in a subsequent analysis.

### Safety and limitations

- Existing ASCT dependencies (FieldTrip, mmultar and local data paths) are
  required for actual execution, not for the pure configuration-grid tests.
- Two configurations are **not** two recording trials. The real-data runner
  uses the trials in your recorded dataset, subject to ordinary ExSetup selection.
- For STEP8, only the currently supported `loc.method='mne'` is allowed.
- `loc.method`, template vs individual T1, and changing `rc.mriRawFolder` have
  not yet been experimentally verified in a real-data multiverse.
- `multiverse.dryRun=true` checks directories and produces a plan without
  running a single ASCT data-processing stage. The first real STEP10 run
  should use two variants and a small existing experiment.
- Automated tests use fake dataset folders and mock callbacks; **they do not**
  establish that FieldTrip / mmultar works with a particular real recording.

Run configuration tests using `runtests('tests/TestMultiverseRealData.m')`.
