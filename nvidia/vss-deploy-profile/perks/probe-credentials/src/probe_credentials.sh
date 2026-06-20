#!/usr/bin/env bash
# probe_credentials — localized from NVIDIA/skills vss-deploy-profile (Apache-2.0). Structured-JSON audit line.
# Read-only credential gate: validates NGC / NVIDIA_API_KEY / HF_TOKEN against their services so a bad
# key fails in seconds, not after a cold NIM start. Reads env vars + curls; never writes generated.env.
# Each probe prints ok / invalid / skip; an unset key is a skip. Non-destructive.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/credentials.json"
LOG="${OUT}.log"
# Always (re)create $OUT so the contract's output_exists holds even if curl is absent or every probe errors.
: > "$OUT"
: > "$LOG"
status="ok"

# Vendored probe reads NGC_CLI_API_KEY / NGC_API_KEY / NVIDIA_API_KEY / HF_TOKEN from the environment.
bash "$HERE/check_credentials.sh" >>"$LOG" 2>&1 || status="degraded"

printf '{"tool":"probe_credentials","status":"%s","log":"%s","out":"%s"}\n' \
  "$status" "$LOG" "$OUT" | tee "$OUT"
