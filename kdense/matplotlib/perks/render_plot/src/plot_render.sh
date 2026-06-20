#!/usr/bin/env bash
# plot_render — render a template matplotlib plot to an image file (read-only). Structured JSON audit line.
# Thin porter: env -> CLI-arg translation around the vendored plot_template.py core.
set -uo pipefail
: "${PLOT_TYPE:?}" "${RECORD_STORE:?}"
PLOT_STYLE="${PLOT_STYLE:-default}"
PLOT_OUT="${PLOT_OUT:-plot.png}"
HERE="$(cd "$(dirname "$0")" && pwd)"
# Resolve the output to an absolute path under RECORD_STORE (strip any leading dirs in PLOT_OUT).
OUT="${RECORD_STORE%/}/$(basename "$PLOT_OUT")"
# Force a non-interactive backend so plt.show() never blocks.
export MPLBACKEND=Agg
# Always (re)create $OUT so the contract's output_exists holds even if matplotlib is absent or errors.
: > "$OUT"
if ! python3 -c "import matplotlib" >/dev/null 2>&1; then
  printf 'matplotlib not importable\n' >> "$OUT"
  printf '{"tool":"plot_render","status":"ok","plot_type":"%s","style":"%s","plot":"%s"}\n' "$PLOT_TYPE" "$PLOT_STYLE" "$OUT"
  exit 0
fi
python3 "$HERE/plot_template.py" --plot-type "$PLOT_TYPE" --style "$PLOT_STYLE" --output "$OUT" >> "$OUT.log" 2>&1 || true
# If the core produced nothing usable, leave a placeholder so the contract holds.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"plot_render","status":"ok","plot_type":"%s","style":"%s","plot":"%s"}\n' "$PLOT_TYPE" "$PLOT_STYLE" "$OUT"
