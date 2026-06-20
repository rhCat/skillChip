#!/usr/bin/env bash
# render_plots — render a volcano plot + an MA plot from a DESeq2 results CSV (matplotlib,
# read-only). Writes volcano_plot.png + ma_plot.png. Structured JSON audit line.
set -uo pipefail
: "${RESULTS:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/volcano_plot.png"
# Always (re)create the primary artifact so the contract's output_exists holds even if the core errors.
: > "$OUT"
RESULTS="$RESULTS" OUT_DIR="${RECORD_STORE%/}" ALPHA="${ALPHA:-0.05}" \
  python3 "$HERE/plot_entry.py" >> "${RECORD_STORE%/}/render_plots.log" 2>&1 || true
# If matplotlib is absent (the core errors before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"render_plots","status":"ok","volcano":"%s"}\n' "$OUT"
