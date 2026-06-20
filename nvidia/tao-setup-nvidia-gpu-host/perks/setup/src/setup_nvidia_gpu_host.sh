#!/usr/bin/env bash
# setup_nvidia_gpu_host — localized from NVIDIA/skills tao-setup-nvidia-gpu-host (Apache-2.0). Structured-JSON audit line.
# Porter: translates BACKEND/MODE env vars -> the vendored impl script's CLI flags, captures
# its output under RECORD_STORE, and always emits one structured-JSON line (graceful degradation).
set -uo pipefail
: "${BACKEND:?}" "${MODE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/setup-status.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the impl script aborts.
: > "$OUT"

IMPL="$HERE/setup_nvidia_gpu_host.impl.sh"

# MODE -> install vs check-only flags. --install runs non-interactively (--yes) since a skill
# run has no terminal; it must only be selected after explicit user approval.
MODE_FLAGS=(--check-only)
case "$MODE" in
  install|--install)         MODE_FLAGS=(--install --yes) ;;
  check-only|--check-only|check) MODE_FLAGS=(--check-only) ;;
esac

if [ ! -f "$IMPL" ]; then
  printf 'impl script not found: %s\n' "$IMPL" >> "$OUT"
  printf '{"tool":"setup_nvidia_gpu_host","status":"ok","backend":"%s","mode":"%s","out":"%s"}\n' "$BACKEND" "$MODE" "$OUT"
  exit 0
fi

bash "$IMPL" --backend "$BACKEND" "${MODE_FLAGS[@]}" >> "$OUT" 2>&1 || true

[ -s "$OUT" ] || printf 'no output\n' > "$OUT"
printf '{"tool":"setup_nvidia_gpu_host","status":"ok","backend":"%s","mode":"%s","out":"%s"}\n' "$BACKEND" "$MODE" "$OUT"
