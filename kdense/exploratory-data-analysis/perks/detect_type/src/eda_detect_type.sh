#!/usr/bin/env bash
# eda_detect_type — detect a scientific file's type + basic metadata (read-only). Structured JSON audit line.
# Thin porter: vendors eda_analyzer.py + eda_detect_type.py; env -> argv; pure stdlib so it always runs.
set -uo pipefail
: "${DATA_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/file_type.json"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/eda_detect_type.py" "$DATA_FILE" "$OUT" \
  >> "${RECORD_STORE%/}/eda_detect_type.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"eda_detect_type","status":"ok","data_file":"%s","file_type":"%s"}\n' "$DATA_FILE" "$OUT"
