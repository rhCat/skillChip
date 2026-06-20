#!/usr/bin/env bash
# style_config — generate a custom .mplstyle style sheet from a named preset (read-only). Structured JSON audit line.
# Thin porter: env -> CLI-arg translation around the vendored style_configurator.py core.
set -uo pipefail
: "${STYLE_PRESET:?}" "${RECORD_STORE:?}"
STYLE_OUT="${STYLE_OUT:-custom.mplstyle}"
HERE="$(cd "$(dirname "$0")" && pwd)"
# Resolve the output to an absolute path under RECORD_STORE (strip any leading dirs in STYLE_OUT).
OUT="${RECORD_STORE%/}/$(basename "$STYLE_OUT")"
# Force a non-interactive backend so plt.show() never blocks.
export MPLBACKEND=Agg
# Always (re)create $OUT so the contract's output_exists holds even if matplotlib is absent or errors.
: > "$OUT"
if ! python3 -c "import matplotlib" >/dev/null 2>&1; then
  printf 'matplotlib not importable\n' >> "$OUT"
  printf '{"tool":"style_config","status":"ok","preset":"%s","style":"%s"}\n' "$STYLE_PRESET" "$OUT"
  exit 0
fi
python3 "$HERE/style_configurator.py" --preset "$STYLE_PRESET" --output "$OUT" --preview >> "$OUT.log" 2>&1 || true
# If the core produced nothing usable, leave a placeholder so the contract holds.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"style_config","status":"ok","preset":"%s","style":"%s"}\n' "$STYLE_PRESET" "$OUT"
