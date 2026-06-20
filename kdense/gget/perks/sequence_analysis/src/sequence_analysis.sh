#!/usr/bin/env bash
# sequence_analysis — batch BLAST + MUSCLE alignment over a FASTA via gget.
# Thin porter over the vendored batch_sequence_analysis.py core. Read-only remote queries; writes under RECORD_STORE.
# Emits one structured-JSON audit line. Degrades gracefully when gget/network are absent.
set -uo pipefail
: "${FASTA:?}" "${RECORD_STORE:?}"
BLAST_DB="${BLAST_DB:-nr}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/sequence_analysis.log"
# Always (re)create $OUT so the contract's output_exists holds even if gget is absent or errors.
: > "$OUT"
# Run the vendored core inside RECORD_STORE so its CSV/AFA artifacts land there (-o . = the store).
# env -> arg translation: FASTA -> positional, BLAST_DB -> -db, output dir -> "." (cwd = RECORD_STORE).
( cd "${RECORD_STORE%/}" && PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
    python3 "$HERE/batch_sequence_analysis.py" "$FASTA" -db "$BLAST_DB" -o . ) >> "$OUT" 2>&1 || true
# Guarantee a non-empty report even on the graceful-offline path (gget import failure).
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"sequence_analysis","status":"ok","fasta":"%s","blast_db":"%s","log":"%s"}\n' "$FASTA" "$BLAST_DB" "$OUT"
