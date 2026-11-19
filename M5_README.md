# ASCT M5 core (isolated implementation)

## Status and limits

This patch **adds real, opt-in MATLAB functions** for stage planning, selected
variant execution, a checked artifact registry, strict donor matching,
checkpointing, retry and preservation of incomplete attempts.

**It is NOT a complete native integration of M5 into ASCT.** The repository
sources `asct_multiverse_realdata.m`, `asct_multiverse_realdata_prepare.m`,
`asct_multiverse_execute.m` and `sc_initAnalysis.m` were not accessible in full
while building this package. Consequently:

- `asct_m5_run` requires an explicit `runnerFcn` implementing the ASCT-specific
  `rc.load` / `rc.stop`, file layouts, `rc.ica2Name`, `rc.iclocName` and ROI
  mapping. There is no production Flanker runner in this package.
- It does **not** change `sc_initAnalysis`, `asct_multiverse_realdata`, MATLAB
  pipeline stages, M4 input data, or team TODOs.
- A future native adapter must validate the actual source stage semantics,
  stage settings (including ROI ordering, data, channels and preprocessing),
  and produce a `compatibility` record from the *effective* run setup.
- It does not yet import existing M1/M4 manifests into M5 registries or support
  whitelisted cross-revision reuse. Use strict matching by default.
- MATLAB/FieldTrip runtime tests must be run on Fossil; the package was only
  checked for file consistency and shell/package integrity in the build
  environment, which does not provide MATLAB.

## New files

- `multiverse/asct_m5_plan.m` — preserves original grid IDs while selecting
  variants and checking the requested stage window (0, 8, 9, 10).
- `multiverse/asct_m5_digest.m` — canonical metadata fingerprint and SHA-256
  checksums (Linux `sha256sum`, macOS `shasum -a 256`).
- `multiverse/asct_m5_registry.m` — write validated, immutable artifact records;
  verify data and metadata on read.
- `multiverse/asct_m5_find.m` — strict stage, parameters, provenance and code
  revision matching; verifies full content before reuse.
- `multiverse/asct_m5_run.m` — dry-run, run, resumable checkpoint, retry with
  non-destructive incomplete-variant archive, explicit callback contract.
- `multiverse/asct_m5_git_identity.m` — revision and dirty status of repository.
- `tests/TestMultiverseM5.m` — independent tests using small mock outputs.

## Runner contract (required for real ASCT execution)

A stage runner must accept `(item, donor, variantFolder)` and return a scalar
struct with:

```
stage                    'ICLOC' | 'ROI' | 'CONN'
executedStartStep        exactly item.startStep
executedStopStep         exactly item.stopStep
files                    paths of nonempty new outputs inside variantFolder
compatibility            struct, the effective output's provenance
usedDonorArtifactId      mandatory if an input donor was provided
```

`compatibility` must contain `dataset`, `subjects`, `conditions`,
`stageSettings`, `upstream`. All fields must describe the *actual* effective
configuration. `upstream` must contain the donor's ID for reused outputs.
An external adapter must *physically* wire donor data to `rc.ica2Name`,
`rc.iclocName`, or the ROI source, and verify the requested early stop is honored.
Simply returning this struct without executing an ASCT stage is not validation.

The current runner checks that the callback confirms the range and used donor,
and that output files exist and hash correctly. It cannot independently certify
the callback's scientific configuration or whether internal pipeline functions
actually consumed the declared files.

## Example plan (does not execute ASCT)

```matlab
addpath(fullfile(pwd,'multiverse'));
specs=struct('id',{'mv_0001','mv_0002','mv_0003'});
opt=struct('selectedVariantIds',{{'mv_0001','mv_0003'}}, ...
    'startStep',10,'stopStep',10);
plan=asct_m5_plan(specs,opt);
assert(isequal(string({plan.id}),["mv_0001" "mv_0003"]));
```

## Example donor matching

First generate and verify a complete native stage artifact with the adapter.
Register it using `asct_m5_registry('add',sourceRoot,artifact)`, where
`artifact` has an explicit stage, revision, producer IDs, compatibility and
file paths. To locate the same input later:

```matlab
request=struct('stage','ROI', ...
    'compatibility',savedCompatibility, ...
    'gitRevision','<the-exact-verified-commit-sha>');
donor=asct_m5_find({sourceRoot},request);
```

No donor is selected based solely on folder names. A changed code revision,
modified file or different compatibility fingerprint is rejected.

## Test on Fossil (from the M5 worktree)

```bash
/opt/matlab_nogui_restricted.sh -batch \
"addpath(pwd);addpath(fullfile(pwd,'multiverse'));t=runtests('tests/TestMultiverseM5.m');disp(t);assert(all([t.Passed]));"
```

Then run full regression tests in the same worktree. Neither command requires
raw participant data. Do not begin real-data cross-run reuse before adding and
testing the native ASCT adapter against an isolated small Flanker fixture.

## Follow-up integration work for complete M5

1. Read current `asct_multiverse_realdata`, `asct_multiverse_execute`,
   `asct_multiverse_realdata_prepare` and `sc_initAnalysis` from the actual
   branch; implement a native stage callback with validated stage boundaries.
2. Build actual stage-specific compatibility records from the effective setup
   and producer files; map `ICA2`, `ICLOC`, `ROI` to the native output paths.
3. Implement import/registration of validated historical M1–M4 artefacts
   without rewriting their original checkpoints.
4. Add A->B->C real-data tests for STEP8-9 and STEP10, numerical equivalence
   against an independent recomputation, runtime termination and resume.
5. Add concurrency locking and, only if scientifically justified, carefully
   audited code-revision equivalence exceptions.

All legacy entry points are unchanged by this additive patch.
