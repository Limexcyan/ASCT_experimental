# ASCT CI starter – intentionally isolated mock, MATLAB

This starter tests synthetic EEG and a **non-production mock** classifier. It does not
load the real ASCT classifier, exercise the real pipeline, or measure classification accuracy.

## Files
- `make_demo_fixture.m` makes 4 x 256 x 12 EEG in microvolts, fs=128 and tiny .mat weights.
- `mock_eeg_predict.m` consumes mock weights and returns demo predictions.
- `tests/TestMockEEG.m` performs four smoke/invariant tests.
- `.github/workflows/matlab-tests.yml` runs tests on PRs and pushes.

## Local use
From repo root in MATLAB:
```matlab
addpath(pwd)
make_demo_fixture(fullfile('tests','fixtures'));
results = runtests('tests');
assert(all([results.Passed]));
```

## CI first-red test
1. Commit all files on a new branch; open PR -> tests should pass.
2. In `mock_eeg_predict.m`, change `probability = 1./(1+exp(-z));` to
   `probability = ones(size(z))*1.2;` -> tests should fail because p exceeds 1.
3. Revert the change -> tests should pass.

## Next integration step
Adapt `mock_eeg_predict` to ASCT's actual classifier input/output contract and replace
an isolated mock invocation with ASCT's real preprocessing/classifier adapter.
The real production weights are not included. Run real-model tests elsewhere.
