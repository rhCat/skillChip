#!/usr/bin/env bash
# validate_training_csv — localized from NVIDIA/skills tao-run-deft-aoi (Apache-2.0). Structured-JSON audit line.
# Validates an assembled ChangeNet training CSV before a GPU training run: required columns, on-disk
# existence of every input_path/golden_path, PASS-preserving label case, and (optionally) train/val
# leakage. The full human-readable report is captured to ${RECORD_STORE}/validation_report.txt.
# Graceful degradation: the report file is always created.
set -uo pipefail
: "${CSV:?}" "${WORKSPACE_ROOT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT="${RECORD_STORE%/}/validation_report.txt"
mkdir -p "${RECORD_STORE%/}"
: > "$REPORT"

ARGS=()
[ -n "${VALIDATION_CSV:-}" ] && ARGS+=(--validation-csv "${VALIDATION_CSV}")
[ -n "${LIGHT:-}" ]         && ARGS+=(--light "${LIGHT}")
[ -n "${IMAGE_EXT:-}" ]     && ARGS+=(--image-ext "${IMAGE_EXT}")

python3 "$HERE/validate_training_csv.py" \
  --csv "${CSV}" \
  --workspace-root "${WORKSPACE_ROOT}" \
  "${ARGS[@]}" \
  >>"$REPORT" 2>&1 || true

[ -s "$REPORT" ] || printf 'validate_training_csv: report unavailable offline\n' > "$REPORT"
printf '{"tool":"validate_training_csv","status":"ok","out":"%s"}\n' "$REPORT"
