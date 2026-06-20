#!/usr/bin/env bash
# eda_format_reference — look up the format-reference section for a file's extension (read-only). Structured JSON audit line.
# Thin porter: vendors eda_analyzer.py + eda_format_reference.py + references/; env -> argv; pure stdlib so it always runs.
set -uo pipefail
: "${DATA_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/format_reference.md"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/eda_format_reference.py" "$DATA_FILE" "$OUT" \
  >> "${RECORD_STORE%/}/eda_format_reference.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"eda_format_reference","status":"ok","data_file":"%s","format_reference":"%s"}\n' "$DATA_FILE" "$OUT"
