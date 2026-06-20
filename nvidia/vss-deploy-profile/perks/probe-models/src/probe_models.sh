#!/usr/bin/env bash
# probe_models — localized from NVIDIA/skills vss-deploy-profile (Apache-2.0). Structured-JSON audit line.
# Probes <BASE_URL>/v1/models for an OpenAI-compatible remote LLM/VLM endpoint and (optionally) verifies
# that EXPECTED_MODEL is advertised. If REMOTE_API_KEY is set it is sent as a Bearer token. Read-only.
set -uo pipefail
: "${BASE_URL:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/models.json"
LOG="${OUT}.log"
# Always (re)create $OUT so the contract's output_exists holds even if curl/jq are absent or the probe fails.
: > "$OUT"
: > "$LOG"
status="ok"

# env -> arg translation: BASE_URL (required) + EXPECTED_MODEL (optional). REMOTE_API_KEY passes through env.
args=("$BASE_URL")
if [ -n "${EXPECTED_MODEL:-}" ]; then
  args+=("$EXPECTED_MODEL")
fi

bash "$HERE/probe_remote_models.sh" "${args[@]}" >>"$LOG" 2>&1 || status="degraded"

printf '{"tool":"probe_models","status":"%s","base_url":"%s","expected_model":"%s","log":"%s","out":"%s"}\n' \
  "$status" "$BASE_URL" "${EXPECTED_MODEL:-}" "$LOG" "$OUT" | tee "$OUT"
