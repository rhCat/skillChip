#!/usr/bin/env bash
# figure_export — render a CSV into a publication-styled figure and save it in the
# requested formats/DPI via the vendored save_publication_figure(). Read-only w.r.t.
# inputs; writes figure files + a manifest under RECORD_STORE. Structured JSON audit line.
set -uo pipefail
: "${DATA_CSV:?}" "${RECORD_STORE:?}"
FORMATS="${FORMATS:-pdf,png}"
DPI="${DPI:-300}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/figure_export.json"
OUT_BASE="${RECORD_STORE%/}/figure"
# Pre-create the manifest so the contract's output_exists holds even on failure.
: > "$OUT"
DATA_CSV="$DATA_CSV" OUT_BASE="$OUT_BASE" FORMATS="$FORMATS" DPI="$DPI" \
  PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/_cli_figure_export.py" > "$OUT" 2>>"${RECORD_STORE%/}/figure_export.err" || true
# Guarantee non-empty JSON output.
[ -s "$OUT" ] || printf '{"tool":"figure_export","status":"degraded","reason":"no output"}' > "$OUT"
printf '{"tool":"figure_export","status":"ok","manifest":"%s","out_base":"%s"}\n' "$OUT" "$OUT_BASE"
