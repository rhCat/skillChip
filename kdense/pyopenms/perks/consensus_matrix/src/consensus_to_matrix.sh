#!/usr/bin/env bash
# consensus_to_matrix — consensusXML -> wide quant matrix CSV (+ optional long, normalization). JSON audit.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/quant_matrix.csv"
LONG="${RECORD_STORE%/}/quant_long.csv"
LOG="${RECORD_STORE%/}/consensus_to_matrix.log"
: > "$OUT"
: > "$LOG"
ARGS=("$INPUT" --out "$OUT")
[ "${LONG_FORMAT:-}" = "1" ] && ARGS+=(--long "$LONG")
[ -n "${NORMALIZE:-}" ]      && ARGS+=(--normalize "$NORMALIZE")
python3 "$HERE/consensus_to_matrix.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"consensus_to_matrix","status":"ok","input":"%s","matrix":"%s"}\n' "$INPUT" "$OUT"
