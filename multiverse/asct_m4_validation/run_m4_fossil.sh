#!/usr/bin/env bash
set -euo pipefail
# Usage: ./run_m4_fossil.sh /path/to/ASCT_experimental /path/to/experiment__multiverse [N]
REPO="${1:?usage: run_m4_fossil.sh REPO EXPERIMENT_ROOT [EXPECTED_VARIANTS]}"
ROOT="${2:?provide experiment__multiverse directory}"
N="${3:-4}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MATLAB_RUNNER="${MATLAB_RUNNER:-/opt/matlab_nogui_restricted.sh}"
cd "$REPO"
printf 'Git revision: '; git rev-parse HEAD
printf 'Git branch: '; git branch --show-current
if [[ -n "$(git status --porcelain)" ]]; then
 echo 'WARNING: working tree is not clean' >&2
fi
# Use a quoted MATLAB literal for file paths.
export M4_REPO="$REPO" M4_ROOT="$ROOT" M4_SCRIPT_DIR="$SCRIPT_DIR" M4_N="$N"
"$MATLAB_RUNNER" -batch "addpath(getenv('M4_SCRIPT_DIR')); addpath(getenv('M4_REPO')); m4_audit(getenv('M4_ROOT'),'ExpectedVariants',str2double(getenv('M4_N')));"
