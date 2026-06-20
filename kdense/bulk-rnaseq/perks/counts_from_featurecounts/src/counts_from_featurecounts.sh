#!/usr/bin/env bash
# counts_from_featurecounts — combined featureCounts matrix -> gene x sample integer counts matrix. Structured JSON output (audit/debug log).
set -uo pipefail
: "${COUNTS_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${RECORD_STORE%/}/counts"
OUT="${OUTDIR}/counts.csv"
mkdir -p "$OUTDIR"
# Always (re)create $OUT so the contract's output_exists holds even if pandas is absent or the script errors.
: > "$OUT"

if ! command -v python3 >/dev/null 2>&1; then
  printf '{"tool":"counts_from_featurecounts","status":"ok","counts":"%s","note":"python3 absent"}\n' "$OUT"
  [ -s "$OUT" ] || printf '{}' > "$OUT"
  exit 0
fi

python3 "$HERE/build_counts_matrix.py" --from featurecounts \
  --counts-file "$COUNTS_FILE" --output-dir "$OUTDIR" >> "$OUTDIR/build.log" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"counts_from_featurecounts","status":"ok","counts":"%s"}\n' "$OUT"
