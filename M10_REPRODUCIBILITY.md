# M10.1 — universal ASCT multiverse artifact snapshots (additive)

**Goal:** stop producing one-off scripts as the only history of experiments. M10.1
records *existing* variant outputs (including manual M4 recovery) in a portable,
read-only-verifiable, machine-readable form. It is **not** the executor, does not
modify any legacy manifests, and does not certify scientifically valid EEG.

## Architecture

- Existing ASCT runner remains the producer of EEG and connectivity files.
- M5 remains responsible for stage planning, strict cross-run reuse, registry,
  transactionality, checkpoint/resume/retry and SHA-256 implementation.
- **M10.1** records a separate snapshot of external or historical stage outputs:
  configuration fingerprints, dataset/variant identity, explicit predecessor IDs,
  producer revision as reported, relative file paths, lengths and SHA-256 digests.
- `snapshot.mat` is the MATLAB-readable source of truth; `snapshot.json` is a
  portable inspection/export format. Its snapshot digest covers the whole MAT
  manifest, including stored roots; verification supports relocated roots via
  explicit overrides without changing the stored manifest.
- `size` mode is quick INVENTORY ONLY. It is never treated as a verified donor.
- No artifact is auto-marked as `passed` in the existing M5 registry and no
  compatibility decision is inferred from equal filenames or NDTF shapes.

## Public MATLAB API

```matlab
manifest = asct_m10_snapshot(spec, '/new/audit/directory');
report   = asct_m10_verify('/new/audit/directory/snapshot.mat');
assert(report.ok);
```

`spec` must have `experimentId`, `codeRevision`, `parameters` (scalar struct)
and ordered `artifacts` entries. Every entry requires `id`, `variantId`,
`stage`, `root`, `patterns`, `upstream`, `settings` (scalar struct).
`expectedCount` is optional but **strongly recommended** to prevent accepting
partial matches of a wildcard as a complete dataset. A dependency
must refer to an **earlier** entry. `patterns` is a cell array of relative
file globs, with wildcards supported only in the final filename; each pattern
must match at least one nonempty file. The capture is fail-closed, creates a
fresh output folder only after all inputs pass, and refuses output paths under
any of its source artifact roots.

The results separate **file completeness** from **cryptographic integrity**:

- `report.complete` = no missing/size/hash-mismatch files.
- `report.ok` = every file was verified against a stored SHA-256.
- `report.files` = file-level statuses `ok`, `missing`, `size_mismatch`,
  `hash_mismatch` or `metadata_only`.
- `report.artifacts` = artifact-level `verified`, `failed` or `inventory_only`.

For relocation, pass `opts.roots=struct('artifactId',{'id1'},'root',{'/new/root'})`
to `asct_m10_verify`. Roots not mentioned use their original saved location.
Capturing large ICA files with full SHA-256 requires reading all bytes. Run only
on completed, quiescent output folders (not while MATLAB is writing).

## Fossil smoke test: existing M4 ROI + connectivity

The included `examples/m10_snapshot_m4_wide_roi_conn.m` captures the 8 LC ROI
signals and STEP10 `mltin`/`mltout` files plus run-level metadata. It does NOT
reconstruct the missing upstream ICA/ICLOC dependency graph; its lineage scope
is explicitly marked `ROI-to-CONN-only`. Extend `spec.artifacts` with ICA2,
classified ICA2 and ICLOC when a full archived snapshot is wanted.

After CI passes and code is checked out into a separate Fossil worktree:

```bash
cd ~/ASCT_M10_validation
/opt/matlab_nogui_restricted.sh -batch \
  "addpath(pwd); addpath(fullfile(pwd,'multiverse')); run(fullfile(pwd,'examples','m10_snapshot_m4_wide_roi_conn.m'));"
```

This creates a NEW directory in `~/m10_snapshots`, not in any M4 output root.
Recorded `codeRevision=46041b6b` is a historical reference from the original
analysis; it is not independently attested for every manual recovery stage.
Before accepting it for strict M5 reuse, obtain exact producer revision,
matching settings, input identity and stage-specific integrity evidence.

## Required next increments (after green CI)

1. M10.2 — generic diff: semantic settings/lineage/outputs, explain precisely
   why two variants or snapshots diverge.
2. M10.3 — **stage-aware replay adapter** binding M5 `run` contracts to ASCT's
   `rc.load`, `rc.stop`, `rc.ica2Name`, `rc.iclocName`, `rc.sigroiName`; dry-run
   and explicit reproducibility checks before any execution.
3. M10.4 — generic diagnostics adapters (`M9 realdata`, residual QC, ICA QC)
   generating reports against stored artifacts rather than rerunning sources.
4. M10.5 — export the full multiverse provenance DAG, reproducibility report,
   environment/version lock, and a Fossil smoke test A→B→C without modifying
   M4 or its original manifest/checkpoints.

**Important:** this patch is a reusable infrastructure primitive, not a claim
that M4's VAR residuals are white, that NDTF is scientifically interpreted,
or that an automatic M5 replay can already run on Fossil.
