#!/usr/bin/env bash
# collect_dynamo_debug_bundle — localized from NVIDIA/skills dynamo-troubleshoot (Apache-2.0). Structured-JSON audit line.
# Read-only: vendors collect_dynamo_debug_bundle.py (kubectl get/describe/logs only; secrets scrubbed).
set -uo pipefail
: "${NAMESPACE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/summary.json"
# Always (re)create the bundle dir + $OUT so the contract's output_exists holds even if kubectl/python are absent or error.
mkdir -p "${RECORD_STORE%/}"
: > "$OUT"

ARGS=(--namespace "${NAMESPACE}" --outdir "${RECORD_STORE%/}")
if [ -n "${DEPLOYMENT_NAME:-}" ]; then
  ARGS+=(--deployment-name "${DEPLOYMENT_NAME}")
fi

# The script writes summary.json (and per-command .txt files) into --outdir and also echoes the summary to stdout.
python3 "$HERE/collect_dynamo_debug_bundle.py" "${ARGS[@]}" >>"$OUT.log" 2>&1 || true

# Graceful degradation: ensure summary.json exists even if python3 is missing or the script bailed before writing it.
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"collect_dynamo_debug_bundle","status":"ok","out":"%s"}\n' "$OUT"
