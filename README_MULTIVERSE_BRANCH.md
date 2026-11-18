# Feature branch: multiverse_analysis

This branch adds a controlled *single-case* multiverse implementation to ASCT.
It is deliberately separate from `main` while its integration and scientific
assumptions are validated.

## First remote-server check: 2 trials + 2 analysis variants

```bash
# In an existing clone on the compute server:
git fetch origin
git switch --track origin/feature/multiverse_analysis
# (If the branch already exists locally, instead use:
#  git switch feature/multiverse_analysis && git pull --ff-only)

matlab -batch "addpath('multiverse'); asct_multiverse_smoke('multiverse_smoke_results');"
```

You should see **two** `ASCT multiverse smoke ...` lines and a final
`ASCT multiverse smoke PASSED: 2 configurations, 2 trials each.`

The generated results are saved under `multiverse_smoke_results/` (ignored by
Git). In particular, inspect `smoke_metrics.csv` and
`multiverse_manifest.csv`.

**Scope of this mockup:** source-level oracle simulation and MVAR/DTF only.
No real ASCT preprocessing, ICA, FieldTrip forward/inverse model, or production
mmultar run is performed. That needs an ASCT-compatible experiment setup,
MEG header/template and datasets, and a larger trial count for bootstrap.

## CI and tests

On a push to `feature/multiverse_analysis`, GitHub Actions workflow
`.github/workflows/matlab-tests.yml` runs MATLAB tests (including
`tests/TestMultiverseSmoke.m`) and the two-trial smoke. Download the workflow
artifact `asct-multiverse-2trials` to inspect the CSV and MAT results.

A failed MATLAB command returns a nonzero exit code; if anything fails, check
`multiverse_manifest.csv` for the per-configuration exception.

For full scope and limitations, see [multiverse/README.md](multiverse/README.md).
