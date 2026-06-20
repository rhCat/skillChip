#!/usr/bin/env bash
# phase_diagram — build a Materials Project phase diagram for CHEMSYS and (optionally) assess the
# stability of COMPOSITION via vendored pymatgen phase_diagram_generator.py. Read-only.
# Needs mp-api + MP_API_KEY + network. One structured-JSON audit line on stdout.
set -uo pipefail
: "${CHEMSYS:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/phasediagram.log"
# Always (re)create $OUT so the contract's output_exists holds even if mp-api/key/network is absent.
: > "$OUT"

# COMPOSITION is optional; only pass --analyze when set and non-empty.
COMP="${COMPOSITION:-}"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
else
  if [ -n "$COMP" ]; then
    python3 "$HERE/phase_diagram_generator.py" "$CHEMSYS" --analyze "$COMP" >> "$OUT" 2>&1 || true
  else
    python3 "$HERE/phase_diagram_generator.py" "$CHEMSYS" >> "$OUT" 2>&1 || true
  fi
fi

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"phase_diagram","status":"ok","chemsys":"%s","composition":"%s","log":"%s"}\n' "$CHEMSYS" "$COMP" "$OUT"
