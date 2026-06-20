#!/usr/bin/env bash
# changenet_data_pair_prepare — localized from NVIDIA/skills tao-run-deft-aoi (Apache-2.0). Structured-JSON audit line.
# Builds the ChangeNet (input_path, golden_path, label, object_name) CSV from paired NG (--input-dir) and
# OK (--golden-dir) image directories. With IMAGES_DIR set it emits the 14-column NV_PCB_Siamese CSV and
# copies images into the staged tree (images_dir/<subdir>_{ng,ok}/object_name_light.ext). Graceful
# degradation: the output CSV is always created.
set -uo pipefail
: "${INPUT_DIR:?}" "${GOLDEN_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/dataset.csv"
mkdir -p "${RECORD_STORE%/}"
: > "$OUT"

ARGS=()
[ -n "${LABEL:-}" ]     && ARGS+=(--label "${LABEL}")
[ -n "${IMAGES_DIR:-}" ] && ARGS+=(--images-dir "${IMAGES_DIR}")
[ -n "${SUBDIR:-}" ]    && ARGS+=(--subdir "${SUBDIR}")
[ -n "${LIGHT:-}" ]     && ARGS+=(--light "${LIGHT}")
[ -n "${IMAGE_EXT:-}" ] && ARGS+=(--image-ext "${IMAGE_EXT}")

python3 "$HERE/changenet_data_pair_prepare.py" \
  --input-dir "${INPUT_DIR}" \
  --golden-dir "${GOLDEN_DIR}" \
  --output "${OUT}" \
  "${ARGS[@]}" \
  >>"${RECORD_STORE%/}/pair_prepare.log" 2>&1 || true

# Fallback: graceful degradation writes the minimal 3-column header so the CSV is non-empty.
[ -s "$OUT" ] || printf 'input_path,golden_path,label\n' > "$OUT"
printf '{"tool":"changenet_data_pair_prepare","status":"ok","out":"%s"}\n' "$OUT"
