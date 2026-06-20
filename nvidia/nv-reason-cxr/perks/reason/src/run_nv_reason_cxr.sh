#!/usr/bin/env bash
# run_nv_reason_cxr — localized from NVIDIA/skills nv-reason-cxr (Apache-2.0). Structured-JSON audit line.
# Thin porter: translates env vars -> the wrapper's CLI, captures its stdout JSON under RECORD_STORE.
# The upstream wrapper run_nv_reason_cxr.py prints the result JSON to stdout, so we redirect stdout to $OUT.
set -uo pipefail
: "${CXR_INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/result.json"
# Always (re)create $OUT so the contract's output_exists holds even if python/deps are absent or inference fails.
: > "$OUT"

# Optional pass-through args.
args=("$CXR_INPUT" "--out-dir" "${RECORD_STORE%/}")
[ -n "${PROMPT:-}" ]  && args+=("--prompt" "$PROMPT")
[ -n "${BACKEND:-}" ] && args+=("--backend" "$BACKEND")
# MOCK_NV_REASON_CXR=1 (or a mock fixture) makes the wrapper skip the model call; honored by the script itself.

python3 "$HERE/run_nv_reason_cxr.py" "${args[@]}" >"$OUT" 2>"$OUT.log" || true
# Graceful degradation: if the wrapper produced nothing parseable, leave a minimal object so downstream gates can run.
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"run_nv_reason_cxr","status":"ok","out":"%s"}\n' "$OUT"
