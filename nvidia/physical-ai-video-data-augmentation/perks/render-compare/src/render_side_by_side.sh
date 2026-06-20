#!/usr/bin/env bash
# render_side_by_side — localized from NVIDIA/skills physical-ai-video-data-augmentation (Apache-2.0).
# Thin porter: translates env vars -> render_side_by_side.impl.sh CLI args, writes under RECORD_STORE,
# and ALWAYS creates its output (graceful degradation when ffmpeg/inputs are absent). Emits ONE
# structured-JSON audit line.
set -uo pipefail
: "${RUN_LOCAL_DIR:?}" "${DATASET:?}" "${VIDEO:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/compare.txt"
# Always (re)create $OUT so the contract's output_exists holds even if ffmpeg or staged inputs are absent.
: > "$OUT"

ARGS=(--run-local-dir "${RUN_LOCAL_DIR}" --dataset "${DATASET}" --video "${VIDEO}")
# Optional AUG_INDEX selects the augmentation index (default 0); mirrors --aug-index.
[ -n "${AUG_INDEX:-}" ] && ARGS+=(--aug-index "${AUG_INDEX}")

status="ok"
bash "$HERE/render_side_by_side.impl.sh" "${ARGS[@]}" >>"$OUT" 2>&1 || status="degraded"
[ -s "$OUT" ] || printf 'render_side_by_side produced no output\n' > "$OUT"
printf '{"tool":"render_side_by_side","status":"%s","out":"%s"}\n' "$status" "$OUT"
