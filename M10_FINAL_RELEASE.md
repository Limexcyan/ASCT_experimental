# ASCT M10 — one-shot reproducibility release candidate

This is **source code ready for MATLAB CI**, not a claim of full real-data integration or scientific validation. It builds on the 66/66 confirmed M5–M10.2 baseline and bundles M10.3, M10.4, M10.5 and a read-only legacy adapter. The GitHub CI acceptance target is **91/91** (66 + 15 replay + 10 final). The user reported 66/66; the 25 new tests are not claimed passed.

## Modules

| Module | Entry point | Contract |
|---|---|---|
| M10.1 | `asct_m10_snapshot`, `asct_m10_verify` | SHA-256 content inventory, root remapping |
| M10.2 | `asct_m10_diff` | manifest-only semantic differences |
| M10.3 | `asct_m10_replay`, `asct_m10_replay_adapter` | sandboxed M5 executor, strict M5 donor |
| M10.4 | `asct_m10_audit` | file integrity + optional WHOS MAT variable/dimension checks; **not** a scientific whiteness/stationarity test |
| M10.5 | `asct_m10_provenance`, `asct_m10_report` | provenance DAG and report JSON/Markdown/DOT |
| Legacy | `asct_m10_legacy_spec` | explicit stage-root mapping, expectedCount and upstream; snapshot only |

## Independent scopes / safety

1. `integrity.ok` means recorded bytes match SHA-256. `metadataPassed` means optional MAT variables and dimensions match. **Neither approves scientific interpretation or reuse.**
2. `reuseAuthorized=false` in all report/QC/graph paths. Only a separately audited M5 donor/registry entry can enter replay.
3. Snapshot source is read-only; report output must not already exist and cannot be placed inside a recorded source root. The original M4 manifest is never overwritten.
4. M10.3 requires a **single verified donor** containing every stage input. STEP9 needs both ICA2 and ICLOC. Multi-donor assembly is NOT supported.
5. M10.3's integration tests use fake executors; native ASCT STEP8–STEP10 and cross-host determinism still require a supervised fossil smoke test.
6. Native M4 STEP0–STEP7 and the complete scientific M4 multiverse are NOT replay-capable under this adapter. Do not conflate a source-level test suite with end-to-end reproduction of the full EEG pipeline.
7. Report MAT inspection uses `whos('-file')` (metadata only). Huge EEG arrays are not loaded. Be aware that hashing the full source files may take disk bandwidth/time.

## CI acceptance

Run the isolated workflow `.github/workflows/multiverse-m5-m9.yml` on the exact release commit. Expected: 91 tests (M5 7, M6 9, M7 4, M8 9, M9 17, M10.1 10, M10.2 10, M10.3 15, M10.final 10). Do not announce green until the runner reports it. A separate native smoke test with dedicated output is mandatory before calling native replay production-ready.

## Real-data acceptance on fossil (read only)

After CI is green, pull source files to a **separate** checkout. Never edit the original M4 manifest/recovery folders. Run `examples/m10_legacy_flanker_wide.m` after inspecting expected paths. It hashes exactly 8 ROI, 8 MVAR inputs and 8 MVAR outputs and tests MAT dimensions. If paths or counts do not match, it fails closed. If successful, reports go in `$HOME/m10_m4_wide_snapshot` and `$HOME/m10_m4_wide_report`. Do not rerun on same output paths unless explicitly creating a new destination.

For any existing snapshot (no writes), set `ASCT_M10_SNAPSHOT=/path/snapshot.mat` and run `examples/m10_acceptance_readonly.m` using a MATLAB `-batch` wrapper as on fossil.

## Explicit remaining gates for 'entire project finished'

- Confirm CI on the release branch (source-level acceptance).
- Execute a native isolated STEP10 M10.3 smoke on fossil; compare output completeness and selected numerical fields against preserved M4, without mutating originals.
- Verify source revisions and dependencies at both ends (MATLAB/FieldTrip/mmultar); capture in manifest.
- Add formal multi-input donor support before supporting independent ICA2 + ICLOC reuse; or use separately attested composite donors.
- Carry out one independently reproduced end-to-end multiverse run and publish the acceptance evidence. **This is not covered by the present patch.**
