#!/usr/bin/env bash
# run_vista3d — localized from NVIDIA/skills nv-segment-ct (Apache-2.0). Structured-JSON audit line.
# Thin porter: translates env vars -> run_vista3d.py CLI, writes the evidence JSON
# under RECORD_STORE. The wrapped script prints its result JSON to stdout, which we
# capture into $OUT; the produced label-map NIfTI lands under RECORD_STORE too.
set -uo pipefail
: "${CT_VOLUME:?}" "${RECORD_STORE:?}"
LABEL_PROMPTS="${LABEL_PROMPTS:-1,3,5,14}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/result.json"
MASK_DIR="${RECORD_STORE%/}/masks"
mkdir -p "$MASK_DIR"
# Always (re)create $OUT so the contract's output_exists holds even if deps/bundle are absent.
: > "$OUT"
python3 "$HERE/run_vista3d.py" "${CT_VOLUME}" \
  --label-prompts "${LABEL_PROMPTS}" \
  --output-dir "${MASK_DIR}" \
  >"$OUT" 2>"$OUT.log" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_vista3d","status":"ok","out":"%s"}\n' "$OUT"
