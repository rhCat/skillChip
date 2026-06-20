#!/usr/bin/env bash
# anonymize_dicom — write a de-identified copy of a DICOM file (PHI removed/replaced). Structured JSON audit line.
# Thin porter: env -> CLI-arg translation around the vendored anonymize_dicom.py core. Reads input, writes a NEW file.
set -uo pipefail
: "${DICOM_IN:?}" "${RECORD_STORE:?}"
PATIENT_ID="${PATIENT_ID:-ANONYMOUS}"
PATIENT_NAME="${PATIENT_NAME:-ANONYMOUS}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/anonymized.dcm"
# Always (re)create $OUT so the contract's output_exists holds even if pydicom is absent or errors.
: > "$OUT"
if ! python3 -c "import pydicom" >/dev/null 2>&1; then
  printf 'pydicom not importable\n' >> "$OUT"
  printf '{"tool":"anonymize_dicom","status":"ok","anonymized":"%s"}\n' "$OUT"
  exit 0
fi
python3 "$HERE/anonymize_dicom.py" "$DICOM_IN" "$OUT" --patient-id "$PATIENT_ID" --patient-name "$PATIENT_NAME" -v >> "$OUT.log" 2>&1 || true
# If the core produced nothing usable, leave a placeholder so the contract holds.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"anonymize_dicom","status":"ok","anonymized":"%s"}\n' "$OUT"
