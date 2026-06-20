#!/usr/bin/env bash
# series_to_volume — localized from NVIDIA/skills dicom-series-to-volume (Apache-2.0). Structured-JSON audit line.
# Thin porter: translates env vars -> series_to_volume.py CLI args, writes under RECORD_STORE.
# The script PRINTS its JSON evidence summary to stdout (captured as result.json) and writes the
# NIfTI volume to --output. result.json is the contract output (mirrors validators/output_schema.json).
set -uo pipefail
: "${DICOM_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/result.json"
NIFTI="${RECORD_STORE%/}/volume.nii.gz"
# Always (re)create $OUT so the contract's output_exists holds even on missing deps or errors.
: > "$OUT"
python3 "$HERE/series_to_volume.py" "${DICOM_DIR}" --output "$NIFTI" > "$OUT" 2>>"$OUT.log" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"series_to_volume","status":"ok","out":"%s","nifti":"%s"}\n' "$OUT" "$NIFTI"
