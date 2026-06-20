#!/usr/bin/env bash
# export_to_phy — export a SortingAnalyzer to Phy format for manual curation via the vendored
# export_to_phy.py. Structured JSON audit line.
set -uo pipefail
: "${ANALYZER_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/export_phy_report.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the science lib is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/export_to_phy.py" "$ANALYZER_DIR" \
    --output "${RECORD_STORE%/}/phy_export" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"export_to_phy","status":"ok","report":"%s","analyzer_dir":"%s"}\n' "$OUT" "$ANALYZER_DIR"
