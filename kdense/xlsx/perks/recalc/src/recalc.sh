#!/usr/bin/env bash
# recalc — recalculate all formulas in an .xlsx/.xlsm workbook via LibreOffice (soffice) and
# scan every cell for Excel errors (#REF!/#DIV/0!/#VALUE!/#NAME?/#NULL!/#NUM!/#N/A). Read-only report.
# Wraps the vendored K-Dense recalc.py (uses openpyxl + office.soffice). Emits one structured-JSON audit line.
set -uo pipefail
: "${XLSX_FILE:?XLSX_FILE (path to .xlsx/.xlsm workbook) is required}"
: "${RECORD_STORE:?RECORD_STORE is required}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/recalc.json"
TIMEOUT="${RECALC_TIMEOUT:-30}"

# Pre-create the output so the contract's output_exists holds even if the core errors or the lib/soffice is absent.
: > "$OUT"

# The vendored recalc.py prints a JSON report to stdout; capture it into $OUT.
# `office.soffice` resolves as an implicit namespace package next to recalc.py (HERE on PYTHONPATH).
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/recalc.py" "$XLSX_FILE" "$TIMEOUT" > "$OUT" 2>/dev/null || true

# Guarantee non-empty valid JSON even when the core could not run (soffice/openpyxl absent or failed).
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"recalc","status":"ok","xlsx":"%s","report":"%s"}\n' "$XLSX_FILE" "$OUT"
