# ASCT M10.2 — deterministic comparison of multiverse snapshots

**Scope:** compare two M10.1 `snapshot.mat` manifests, not their live EEG data.
This makes the comparison usable after moving archives between storage roots or
when the original machine is offline. It does not run stages or change M4.

```matlab
addpath('multiverse');
a=fullfile(getenv('HOME'),'snapshots','runA','snapshot.mat');
b=fullfile(getenv('HOME'),'snapshots','runB','snapshot.mat');
d=asct_m10_diff(a,b);
d.summary
{d.parameterChanges.path}'
{d.artifacts.status}'
{d.files.status}'
```

`d.scope='manifest_only'` always. `d.metadataEquivalent` means **only** that
both stored manifests make identical semantic claims, including matching
codeRevision, experimentId, parameters, stage settings, dependency IDs, and
SHA-256 file listings. It is *not* an integrity pass on current disk bytes, and
is never an M5 reuse authorization. For actual files run `asct_m10_verify`
independently on both snapshots (with root overrides if necessary).

- `parameterChanges`: nested paths (`parameters.model.nested.lambda`), change
  type, truncated before/after JSON previews.
- `artifacts`: deterministic by `id`; `added`, `removed`, `modified`,
  `unchanged`, `unverified`; stage, variant, nested settings changes, upstream
  ID additions/removals, optional expectedCount change, root relocation.
- `files`: deterministic by `(artifactId,relativePath)`; matching SHA-256 and
  size -> `unchanged`; different digest or size -> `modified`; only byte sizes
  available -> **`unverified`**, even if equal. Portable path separators.
- `summary`: counts per status.
- `sourceRoot` relocations, snapshot capture times and artifact/file ordering
  do **not** change semantic equivalence, but `rootRelocated` reports location
  changes. Stage settings and upstream dependencies are compared by ID, not by
  their position in a snapshot.

The reader checks each manifest's stored M10.1 snapshot/setting fingerprints
before comparing. Those digests detect accidental corruption, but are *not*
cryptographic signatures or independent proof of provenance: someone with
write access can replace a manifest and recompute its digest. It does not
verify code revisions, numerical equivalence of models, or scientific accuracy.

## CI gate

10 new MATLAB tests in `tests/TestMultiverseM10Diff.m` cover: portable roots,
nested parameter paths, same-size hash changes, lineage/settings divergence,
stage add/remove, size-only snapshots, file order, manifest tampering, missing
snapshots, and that the comparison does not touch source data. Existing M5–M10.1
tests remain unchanged. Expected count **66 tests** after applying this patch.

Use an additive Git commit; wait for GitHub Actions R2024b green before M10.3.
