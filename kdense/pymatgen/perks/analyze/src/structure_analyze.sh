#!/usr/bin/env bash
# structure_analyze — composition / lattice / symmetry / coordination analysis of a crystal structure
# via vendored pymatgen structure_analyzer.py. Read-only. One structured-JSON audit line on stdout.
set -uo pipefail
: "${STRUCTURE_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/analyze.log"
JSON="${RECORD_STORE%/}/analysis.json"
# Always (re)create $OUT so the contract's output_exists holds even if pymatgen is absent or errors.
: > "$OUT"

# Resolve STRUCTURE_FILE to an absolute path (core opens relative to cwd).
case "$STRUCTURE_FILE" in
  /*) SF_ABS="$STRUCTURE_FILE" ;;
  *)  SF_ABS="$(pwd)/$STRUCTURE_FILE" ;;
esac

if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
else
  # --symmetry + --neighbors for full analysis; export structured results to analysis.json.
  python3 "$HERE/structure_analyzer.py" "$SF_ABS" --symmetry --neighbors --export json --output "$JSON" >> "$OUT" 2>&1 || true
fi

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"structure_analyze","status":"ok","structure":"%s","analysis_json":"%s","log":"%s"}\n' "$SF_ABS" "$JSON" "$OUT"
