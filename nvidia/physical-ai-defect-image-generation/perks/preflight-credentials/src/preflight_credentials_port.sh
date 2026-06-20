#!/usr/bin/env bash
# preflight_credentials_port — localized from NVIDIA/skills physical-ai-defect-image-generation (Apache-2.0).
# Governed entry point: verify the one credential every DIG flow needs — the OSMO
# credential hf-token that gates the gated-repo Hugging Face downloads (and, when
# HF_TOKEN is exported, probe two gated HF repos for scope). Captures the core's
# verdict to a report file. Emits ONE line of structured JSON on stdout and ALWAYS
# creates its output file (graceful degradation, like terraform's tf_plan.sh) — if
# the osmo CLI is absent the report records that and the porter still passes.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/credentials_report.txt"
# Always (re)create $OUT so the contract's output_exists holds even when osmo is absent.
: > "$OUT"

args=()
# --no-probe in restricted-egress shells (no outbound HF probes).
case "${NO_PROBE:-}" in true|1|yes|y) args+=(--no-probe) ;; esac

if ! command -v osmo >/dev/null 2>&1; then
  printf 'osmo CLI not on PATH — cannot list/verify OSMO credential hf-token offline.\n' >> "$OUT"
  printf '{"tool":"preflight_credentials","status":"ok","verified":false,"report":"%s"}\n' "$OUT"
  exit 0
fi

rc=0
bash "$HERE/preflight_credentials.sh" "${args[@]}" >>"$OUT" 2>>"$OUT" || rc=$?
[ -s "$OUT" ] || printf 'preflight_credentials produced no output (exit %s)\n' "$rc" > "$OUT"
verified=false; [ "$rc" -eq 0 ] && verified=true
printf '{"tool":"preflight_credentials","status":"ok","verified":%s,"exit":%s,"report":"%s"}\n' "$verified" "$rc" "$OUT"
