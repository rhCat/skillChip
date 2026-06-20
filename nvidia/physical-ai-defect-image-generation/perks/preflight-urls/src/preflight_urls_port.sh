#!/usr/bin/env bash
# preflight_urls_port — localized from NVIDIA/skills physical-ai-defect-image-generation (Apache-2.0).
# Governed entry point: verify the DIG URL artifacts a given flow+usecase needs are
# present under DIG_URL_ROOT (models/pretrained, models/<usecase>, datasets/<usecase>/raw,
# datasets/pcb/assets, ...) before a submit. Captures the core's checklist and verdict.
# Emits ONE line of structured JSON on stdout and ALWAYS creates its output file
# (graceful degradation, like terraform's tf_plan.sh) — offline / no-osmo records
# that and the porter still passes.
set -uo pipefail
: "${FLOW:?}" "${USECASE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/urls_report.txt"
# Always (re)create $OUT so the contract's output_exists holds even when osmo is absent.
: > "$OUT"

args=("$FLOW" "$USECASE")
[ -n "${VARIANT:-}" ] && args+=("$VARIANT")

# The core reads DIG_URL_ROOT / USE_PRETRAINED_CHECKPOINT / USE_USD2ROI_DAY1 from env.
export DIG_URL_ROOT="${DIG_URL_ROOT:-s3://osmo-workflows/dig}"
[ -n "${USE_PRETRAINED_CHECKPOINT:-}" ] && export USE_PRETRAINED_CHECKPOINT
[ -n "${USE_USD2ROI_DAY1:-}" ] && export USE_USD2ROI_DAY1

if ! command -v osmo >/dev/null 2>&1; then
  printf 'osmo CLI not on PATH — cannot list DIG URL artifacts under %s offline (flow=%s usecase=%s).\n' \
    "$DIG_URL_ROOT" "$FLOW" "$USECASE" >> "$OUT"
  printf '{"tool":"preflight_urls","status":"ok","verified":false,"flow":"%s","usecase":"%s","report":"%s"}\n' \
    "$FLOW" "$USECASE" "$OUT"
  exit 0
fi

rc=0
bash "$HERE/preflight_urls.sh" "${args[@]}" >>"$OUT" 2>>"$OUT" || rc=$?
[ -s "$OUT" ] || printf 'preflight_urls produced no output (exit %s)\n' "$rc" > "$OUT"
verified=false; [ "$rc" -eq 0 ] && verified=true
printf '{"tool":"preflight_urls","status":"ok","verified":%s,"exit":%s,"flow":"%s","usecase":"%s","report":"%s"}\n' \
  "$verified" "$rc" "$FLOW" "$USECASE" "$OUT"
