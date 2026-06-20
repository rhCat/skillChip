#!/usr/bin/env bash
# check_conda — localized from NVIDIA/skills holoscan-setup (Apache-2.0). Structured-JSON audit line.
# Detects Conda installs (even off PATH) and which envs import holoscan. Read-only.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/conda.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the impl errors.
: > "$OUT"
bash "$HERE/check_conda.impl.sh" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '✗ conda not detected\n' > "$OUT"
printf '{"tool":"check_conda","status":"ok","out":"%s"}\n' "$OUT"
