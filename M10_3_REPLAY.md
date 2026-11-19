# ASCT M10.3 — stage-aware replay adapter (M5 bridge)

**Status:** test-gated, additive implementation. Native MATLAB/ASCT replay against
real EEG has NOT been integration-tested. This feature must not be used on
historical M4 checkpoint directories until donor promotion/import is separately
audited. M10 snapshots record history but do **not** authorize M5 reuse.

## Architecture

M10.3 does **not** implement a second scheduler. It routes M5 plans to M5's
transactional runner/checkpoints/registry:

```matlab
[plan,results] = asct_m10_replay(specs,baseSetup,opts,executeFcn);
```

- `asct_m5_plan` selects variant IDs and the range `startStep..stopStep`.
- `asct_m5_run` handles dry-run, `resume`, `retryFailed`, strict donor selection,
  registry checksums, clean Git revision, new output folders and checkpoint.
- `asct_m10_replay_adapter` is a callback implementing M5's runner contract.
  It accepts a **verified M5 donor**, copies its recorded files into
  `variants/<id>/input_donor`, checks copied SHA-256 digests, configures ASCT
  to write in `variants/<id>/output`, then calls the explicitly supplied executor.
- When the executor returns, M10.3 verifies the stage-specific count of
  primary files (`*_icloc.mat`, `*sigroi_lc.mat`/`*sigroi_unc.mat`, or
  `*_mltout.mat`) before M5 marks a variant passed. It can also verify exact
  relative paths via `opts.adapter.expectedMainPaths`.

**No external donor folder is writable through `rc.expFolder`/`rc.*Name`.**
Sandboxing is done by copying, not symlinking. This is expensive for large ICA
files and requires enough free disk space. Native pipeline code may have other
side effects that cannot be guaranteed without a real-data integration run.

## Explicit configuration

```matlab
% All values below are placeholders, NOT instructions to run on M4 as-is.
specs = struct('id','mv_0001','changes', ...
    struct('con',struct('mvarOrd',7)));
opts.selection = struct('selectedVariantIds',{{'mv_0001'}}, ...
    'startStep',10,'stopStep',10);
opts.adapter = struct('dataset','some-dataset', ...
    'subjects',{{'participantA'}},'conditions',{{'DC1'}}, ...
    'expectedMainFiles',1);
opts.m5 = struct('outputRoot','/new/isolated/replay-run', ...
    'runId','replay_001','gitRevision','<full-clean-commit-SHA>', ...
    'gitDirty',false,'repoRoot','/worktree/ASCT_experimental', ...
    'inputs',struct('variantId','mv_0001', ...
        'compatibility',verifiedInputCompatibility), ...
    'donorRoots',{{'/verified/M5-donor-run'}}, ...
    'dryRun',true);
executor = @(p) asct_multiverse_execute(p,[],[]);
[plan,preview] = asct_m10_replay(specs,setup,opts,executor);
% Only after independent data/source compatibility checks and disk budgeting:
% opts.m5.dryRun=false;
% [plan,result] = asct_m10_replay(specs,setup,opts,executor);
```

`opts.m5.inputs` must be the **same exact compatibility** that was registered
for the M5 donor. The adapter additionally checks `dataset`, `subjects`, and
`conditions`. No matching-by-filename and no automatic promotion from M10
snapshot to M5 donor registry is performed.

## Supported stage ranges

| startStep | M5 input stage | Source fields | Mandatory input data |
|-----------|----------------|---------------|----------------------|
| 8 | ICA2 | `rc.ica2Name` | `6_ICA2/*_ica2.mat` |
| 9 | ICLOC | `rc.ica2Name`, `rc.iclocName` | BOTH ICA2 and `7_SOURCEACT/icloc/*icloc.mat` |
| 10 | ROI | `rc.sigroiName` | `7_SOURCEACT/DC*/(lc|unc)/*sigroi*.mat` |

`stopStep` can be 8, 9 or 10, but not earlier than `startStep`. STEP0–7,
statistics STEP11, automatic multi-donor resolution and full historical M4
replay are not supported in this increment. STEP9 **cannot** currently use
independent ICA2 and ICLOC donors, because M5 accepts one input donor per
variant. A composite M5-verified donor containing both inputs is accepted;
otherwise replay fails closed before the executor is called.

For safety, variants cannot modify upstream `chan`, `filter`, `seg`, `ar`, `ica`,
`design` or `rc` fields. STEP10 can only vary `con` and cannot change
`decimate`, `removeERP` or `sensorLevel`; STEP9 may change `loc.ROI` but not
other localization settings. Full stage-specific scientific compatibility
requires a separately validated adapter to existing setup/stage semantics;
this simple fence is *necessary but not sufficient*.

## Known limitations and next work

1. **Native smoke tests:** run new dry-run, STEP10 isolated real-data run and
   validate exact expected output paths and numerical agreement. Do not mutate
   original M4 sources/checkpoints. M10.3's new tests use mock executor files.
2. **Historical donor import:** verify full provenance, version, settings,
   input mapping and artifact completeness before registering any legacy M4
   output as a strict M5 donor. Snapshot equivalence alone is insufficient.
3. **Multi-input stages:** extend M5 to explicitly attest two inputs for STEP9
   and preserve both hashes/provenance edges; don't silently use any external
   ICA2 location not covered by the donor contract.
4. **Scientific output checks:** file existence and count do not validate EEG
   content, model stability, signal shapes or NDTF semantics. Connect M8/M9 QC
   after a successful replay, as a separate result layer.
5. **Concurrency:** M5's current runner has no cross-process lock. Do not run
   two jobs against the same outputRoot.

## CI gate

`tests/TestMultiverseM10Replay.m` adds 15 tests. Existing green baseline:
66 tests; expected after this patch: **81 tests**. No test uses real EEG,
FieldTrip, or MATLAB GUI. Test pass cannot be asserted until GitHub Actions
R2024b reports it.
