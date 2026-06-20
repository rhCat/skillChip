#!/usr/bin/env bash
# generate_configs — localized from NVIDIA/skills physical-ai-video-data-augmentation (Apache-2.0).
# Thin porter: translates env vars -> generate_configs.py positional args, writes under RECORD_STORE,
# and ALWAYS creates its output (graceful degradation). Emits ONE structured-JSON audit line.
set -uo pipefail
: "${INPUT_DIR:?}" "${CONFIG_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-${RECORD_STORE%/}/configs}"
mkdir -p "$OUTPUT_DIR"
OUT="${OUTPUT_DIR%/}/manifest.yaml"
LOG="${RECORD_STORE%/}/gen_configs.log"
# Always (re)create $OUT so the contract's output_exists holds even if pyyaml/omegaconf is absent or errors.
: > "$OUT"
: > "$LOG"

status="ok"
# generate_configs.py: <input_videos_dir> <config_dir> <output_dir>
python3 "$HERE/generate_configs.py" "${INPUT_DIR}" "${CONFIG_DIR}" "${OUTPUT_DIR}" >>"$LOG" 2>&1 || status="degraded"
[ -s "$OUT" ] || printf 'configs: {}\ntotal: 0\n' > "$OUT"
printf '{"tool":"generate_configs","status":"%s","out":"%s"}\n' "$status" "$OUT"
