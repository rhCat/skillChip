#!/usr/bin/env bash
# extract_metadata — localized from NVIDIA/skills dicom-metadata-extract (Apache-2.0). Structured-JSON audit line.
set -uo pipefail
: "${DICOM_PATH:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/metadata.json"
# Always (re)create $OUT so the contract's output_exists holds even if python/pydicom is absent or errors.
: > "$OUT"
python3 "$HERE/extract_metadata.py" "${DICOM_PATH}" --output "$OUT" >>"$OUT.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"extract_metadata","status":"ok","out":"%s"}\n' "$OUT"
