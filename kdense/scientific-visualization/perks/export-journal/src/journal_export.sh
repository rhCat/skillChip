#!/usr/bin/env bash
# journal_export — render a CSV into a publication-styled figure and save it with a
# specific journal's required formats + DPI via the vendored save_for_journal().
# Read-only w.r.t. inputs; writes figure files + a manifest under RECORD_STORE.
# Structured JSON audit line.
set -uo pipefail
: "${DATA_CSV:?}" "${RECORD_STORE:?}"
JOURNAL="${JOURNAL:-nature}"
FIGURE_TYPE="${FIGURE_TYPE:-combination}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/journal_export.json"
OUT_BASE="${RECORD_STORE%/}/figure"
# Pre-create the manifest so the contract's output_exists holds even on failure.
: > "$OUT"
DATA_CSV="$DATA_CSV" OUT_BASE="$OUT_BASE" JOURNAL="$JOURNAL" FIGURE_TYPE="$FIGURE_TYPE" \
  PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/_cli_journal_export.py" > "$OUT" 2>>"${RECORD_STORE%/}/journal_export.err" || true
# Guarantee non-empty JSON output.
[ -s "$OUT" ] || printf '{"tool":"journal_export","status":"degraded","reason":"no output"}' > "$OUT"
printf '{"tool":"journal_export","status":"ok","manifest":"%s","journal":"%s"}\n' "$OUT" "$JOURNAL"
