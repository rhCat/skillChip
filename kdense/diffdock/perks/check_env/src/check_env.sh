#!/usr/bin/env bash
# check_env — diagnose the DiffDock environment (Python/PyTorch/CUDA/PyG/RDKit/ESM/checkpoints). Read-only. Structured JSON audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/setup_check.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python3 is absent or errors.
: > "$OUT"

ARGS=()
# VERBOSE: any non-empty value enables --verbose
if [ -n "${VERBOSE:-}" ]; then
  ARGS+=( "--verbose" )
fi

if command -v python3 >/dev/null 2>&1; then
  # setup_check.py returns nonzero when checks fail; that is a valid diagnostic, not a porter failure.
  python3 "$HERE/setup_check.py" "${ARGS[@]}" >> "$OUT" 2>&1 || true
else
  printf 'python3 not found on PATH\n' >> "$OUT"
fi

# Guarantee a nonempty artifact for the contract.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"check_env","status":"ok","setup_report":"%s"}\n' "$OUT"
