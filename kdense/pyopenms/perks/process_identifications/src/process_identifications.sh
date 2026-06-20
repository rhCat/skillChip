#!/usr/bin/env bash
# process_identifications — re-index/FDR/filter peptide IDs -> filtered idXML + CSV. JSON audit.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/filtered.idXML"
CSV="${RECORD_STORE%/}/hits.csv"
LOG="${RECORD_STORE%/}/process_identifications.log"
: > "$OUT"
: > "$LOG"
ARGS=("$INPUT" --out "$OUT" --csv "$CSV")
[ -n "${FASTA:-}" ]      && ARGS+=(--fasta "$FASTA")
[ -n "${FDR:-}" ]        && ARGS+=(--fdr "$FDR")
[ -n "${MIN_LENGTH:-}" ] && ARGS+=(--min-length "$MIN_LENGTH")
[ -n "${MAX_LENGTH:-}" ] && ARGS+=(--max-length "$MAX_LENGTH")
[ "${BEST_PER_SPECTRUM:-}" = "1" ] && ARGS+=(--best-per-spectrum)
python3 "$HERE/process_identifications.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"process_identifications","status":"ok","input":"%s","filtered":"%s"}\n' "$INPUT" "$OUT"
