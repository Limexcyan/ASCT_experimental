# ASCT M1 completion + M2 — STEP8 localization multiverse

## Scope

This changes software, not scientific conclusions. M1's generic stage cache and
resume passed 61/61 MATLAB tests on fossil before this patch. This patch adds
10 M2 tests and an **executable real-data integration pilot**; the latter must
be run on fossil with actual ICA2 and FieldTrip before declaring M1 integrated.

## Supported, actual ASCT localization controls

`MNE_functions/sc_sourceLocalize.m` consumes:

- `loc.norm='lambda'` with positive `loc.lambda` -> `cfg.mne.lambda`;
- `loc.norm='cov'` with positive `loc.noiseLev` -> per-IC `cfg.mne.snr`;
- `loc.noiseLev` (positive) -> `cfg.mne.noisecov` in **both** modes;
- `loc.depthWeight` in [0,1] -> leadfield column-normalization parameter
  (`ft_prepare_leadfield(cfg).normalizeparam`) when nonzero; zero disables it;
- `loc.method='mne'` only. Other inverse solvers are not implemented.

Note: changing `loc.lambda` has **no effect** under `loc.norm='cov'` and is
rejected as an inert factor. Use an `includeFcn` to prune redundant combos.

```matlab
mv.factors.loc.norm={'lambda','cov'};
mv.factors.loc.lambda=[0.05 0.2];
mv.factors.loc.noiseLev=[1 2];
mv.factors.loc.depthWeight=[0 0.5];
mv.includeFcn=@(c) strcmp(c.loc.norm,'lambda') || c.loc.lambda==0.05;
mv.maxRuns=12; % 3 norm/lambda combinations x 2 noise x 2 depth
```

Set `mv.strictLocalization=true` to enforce all real STEP8 requirements.
This is opt-in to preserve old M1 unit fixtures with incomplete dummy setups.
Set `mv.strictArtifacts=true` to require nonempty on-disk ICLOC, ROI and
`*_mltout.mat` files before a variant can be marked `passed`.

## Leadfield and shared MRI protection

- `runsetup.rc.multiverseIsolatedLeadfield=true` for STEP0/8/9 runs. A
  multiverse-specific leadfield is not saved back into the shared subject MRI
  `SC/sourcemodel_indiv_acpc.mat` by `sc_sourceLocalize`.
- If depth weighting is a factor, `runsetup.loc.force_lf=1` guarantees a new
  leadfield using the requested weight rather than a prior precomputed one.
- For individual T1, `sc_6_SOURCE_LOC_ICA` reuses *existing* subject MRI/head
  models in isolated mode, refusing to rebuild them into the shared folder.
  `sc_7_SIG_RECON` also refuses to create missing MRI segmentation into a
  shared path during the multiverse. Prepare these singleverse prerequisites
  first. The first Flanker pilot intentionally uses template-only MRI.
- Source localization writes per-variant `7_SOURCEACT/icloc` files; STEP9
  writes per-variant ROIs; STEP10 writes connectivity results.
- `asct_multiverse_execute` initializes FieldTrip for STEP8/9 and STEP11.

These protections do **not** make raw STEP0/preprocessing or arbitrary
external scripts magically side-effect free; inspect per-stage dependencies
before enabling additional factor groups on valuable datasets.

## Real-data end-to-end M1 acceptance on fossil

New file: `flanker_multiverse_m1_m2_setup.m` (standalone ExSetup copy; does
not overwrite or invoke the previous flanker_step10_setup). It uses:

- Baseline `ana1/6_ICA2` in `/mnt/devv/Exp/LG/wprawki/flanker`;
- **A1 only**, two experimental DCs, template source model;
- four variants: depthWeight=[0 0.5] × con.varNorm=[0 1];
- `runStatistics=false`, `cacheStages=true`, `strictArtifacts=true`,
  `strictLocalization=true`, a **new** outputName;
- initial `dryRun=true` (read-only planning aside from the plan manifest).

```bash
cd ~/ASCT_experimental
/opt/matlab_nogui_restricted.sh -batch "addpath(pwd); flanker_multiverse_m1_m2_setup"
```

Inspect the plan and verify the baseline A1 ICA2 exists. The dry run will
create a planned manifest but **no** variant connectivity output. Then set
`multiverse.dryRun=false` in the **new** setup and run the same command.

Expected actual execution order:

1. `mv_0001`: STEP8 -> STEP9 -> STEP10, depthWeight=0, varNorm=0;
2. `mv_0002`: STEP8 -> STEP9 -> STEP10, depthWeight=.5, varNorm=0;
3. `mv_0003`: STEP10 only, reusing ROI from `mv_0001`, varNorm=1;
4. `mv_0004`: STEP10 only, reusing ROI from `mv_0002`, varNorm=1.

Successful real execution is checked by the setup itself via:

```matlab
asct_multiverse_m1m2_verify( ...
  '/mnt/devv/Exp/LG/wprawki/flanker', 'ana1_mv_flanker_m1_m2_v1');
```

The verifier checks all four statuses and saved ExSetups, correct donor
identities, STEP8 leadfield isolation, nonempty ICLOC, ROI (per DC), and
connectivity artifacts (per DC). It writes `m1_m2_integration_report.csv`
under the multiverse root. This is a **technical** integration check,
not a validation of inferred EEG connectivity. The historical Flanker STEP10
audit is not applicable to variant 1/2 here because their input ROI is produced
in their own folders, not always in sourceAnalysis/7_SOURCEACT.

Do not rerun an already completed name without `resume=true` and an identical
plan. If failure occurs, inspect the log/manifest; use `mv.resume=true` and
`mv.retryFailed=true` only after confirming partial files can be archived.

## Tests

```bash
/opt/matlab_nogui_restricted.sh -batch \
 "addpath(pwd); t=runtests('tests/TestMultiverseM2.m'); disp(t); assert(all([t.Passed]));"
/opt/matlab_nogui_restricted.sh -batch \
 "addpath(pwd); t=runtests('tests'); disp(t); assert(all([t.Passed]));"
```

The new tests use mock output files. The actual template/FieldTrip pipeline
can only be tested on an installation with matching baseline ICA2 data.
