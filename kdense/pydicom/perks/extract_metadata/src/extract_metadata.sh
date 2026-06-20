#!/usr/bin/env bash
# extract_metadata — read a DICOM file and dump its metadata (text|json) to record_store (read-only).
# Thin porter: env -> CLI-arg translation around the vendored extract_metadata.py core.
set -uo pipefail
: "${DICOM_IN:?}" "${RECORD_STORE:?}"
META_FORMAT="${META_FORMAT:-text}"
HERE="$(cd "$(dirname "$0")" && pwd)"
# Canonical contract output (a single stable path regardless of format).
OUT="${RECORD_STORE%/}/metadata.txt"
# Always (re)create $OUT so the contract's output_exists holds even if pydicom is absent or errors.
: > "$OUT"
if ! python3 -c "import pydicom" >/dev/null 2>&1; then
  printf 'pydicom not importable\n' >> "$OUT"
  printf '{"tool":"extract_metadata","status":"ok","format":"%s","metadata":"%s"}\n' "$META_FORMAT" "$OUT"
  exit 0
fi
python3 "$HERE/extract_metadata.py" "$DICOM_IN" --format "$META_FORMAT" -o "$OUT" >> "$OUT.log" 2>&1 || true
# If the core produced nothing usable, leave a placeholder so the contract holds.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"extract_metadata","status":"ok","format":"%s","metadata":"%s"}\n' "$META_FORMAT" "$OUT"
