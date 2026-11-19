# ASCT M10 final release-candidate installation

## One-patch installation on Mac, starting from GREEN M10.2 (66/66)

Use the **combined** `ASCT_M10_3_to_M10_final_from_M10_2.patch`. Do not also apply older M10.3 patch.

```bash
cd ~/Documents/asct_m5
git switch feature/m10-semantic-diff
git pull --ff-only origin feature/m10-semantic-diff
test -z "$(git status --porcelain)" || { echo 'STOP: working tree dirty'; exit 1; }
git switch -c feature/m10-final-one-shot
PATCH="$HOME/Downloads/ASCT_M10_3_to_M10_final_from_M10_2.patch"
git apply --check "$PATCH"
git apply --index "$PATCH"
git diff --cached --check
git diff --cached --stat
git commit -m "M10: complete replay, legacy capture, QC and provenance reporting"
git push -u origin feature/m10-final-one-shot
```

If `feature/m10-final-one-shot` already exists, create a new uniquely named branch. Do not force-push.

## Delta installation if current checkout already has M10.3

Use only `ASCT_M10_4_5_delta_after_M10_3.patch` and the same `git apply --check` / `git apply --index` / commit workflow on the confirmed M10.3 branch.

## CI gate

The isolated GitHub Action must return **91/91** (previous 66 + M10.3 15 + M10.4/5 10). This package has NOT executed MATLAB R2024b locally. If failures occur, inspect the exact failure IDs before making new modifications. Do not merge until green.

## Integration gate on fossil

Only after CI, bring the code to a separate checkout. Confirm exact artifact paths with `find` before running `examples/m10_legacy_flanker_wide.m`. The latter reads files in existing STEP9 and STEP10 directories, creates a snapshot and report under `$HOME`; the original M4 manifest, checkpoints, EEG and models are not modified.

On fossil use one-line wrapper evaluation:

```bash
/opt/matlab_nogui_restricted.sh -batch "run('/path/to/ASCT_experimental/examples/m10_legacy_flanker_wide.m')"
```

The 24-file snapshot is a *partial* Flanker M4 provenance test, **not** full STEP0–STEP10 reconstruction. It captures 8 STEP9 ROI signals, 8 STEP10 MVAR inputs and 8 STEP10 MVAR outputs.

## What this release does NOT guarantee

- Independent real-data execution of M10.3 has not been shown; run a supervised isolated STEP10 acceptance with a strict M5 donor, not a legacy snapshot.
- M5 currently supports one donor per variant. STEP9 requires both ICA2+ICLOC in that one verified donor.
- Scientific tests of residual whiteness or NDTF edge interpretation remain separate, optional QC layers, not release blockers for tooling.
- Full project completion requires an end-to-end multiverse replay on separate outputs plus validated environment fingerprints. Do not describe the present source-only build as fully validated.
