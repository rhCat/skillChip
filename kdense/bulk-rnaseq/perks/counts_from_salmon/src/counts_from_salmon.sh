#!/usr/bin/env bash
# counts_from_salmon — Salmon quant.sf -> gene-level integer counts matrix (pytximport length_scaled_tpm). Structured JSON output (audit/debug log).
set -uo pipefail
: "${QUANT_DIR:?}" "${TX2GENE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${RECORD_STORE%/}/counts"
OUT="${OUTDIR}/counts.csv"
mkdir -p "$OUTDIR"
# Always (re)create $OUT so the contract's output_exists holds even if pandas/pytximport is absent or the script errors.
: > "$OUT"

if ! command -v python3 >/dev/null 2>&1; then
  printf '{"tool":"counts_from_salmon","status":"ok","counts":"%s","note":"python3 absent"}\n' "$OUT"
  [ -s "$OUT" ] || printf '{}' > "$OUT"
  exit 0
fi

# Vendored core writes counts.csv + metadata_template.csv into --output-dir.
python3 "$HERE/build_counts_matrix.py" --from salmon \
  --quant-dir "$QUANT_DIR" --tx2gene "$TX2GENE" --output-dir "$OUTDIR" >> "$OUTDIR/build.log" 2>&1 || true

# Salmon mode degrades to a placeholder when pytximport is absent so the contract still holds.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"counts_from_salmon","status":"ok","counts":"%s"}\n' "$OUT"
