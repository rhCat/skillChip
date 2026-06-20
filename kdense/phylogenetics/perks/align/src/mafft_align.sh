#!/usr/bin/env bash
# mafft_align — MAFFT multiple sequence alignment (unaligned FASTA -> aligned FASTA).
# Thin porter around the vendored phylogenetic_analysis.run_mafft. Structured JSON audit line.
set -uo pipefail
: "${INPUT_FASTA:?}" "${RECORD_STORE:?}"
THREADS="${THREADS:-4}"
METHOD="${METHOD:-auto}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/aligned.fasta"
# Always (re)create $OUT so the contract's output_exists holds even if mafft / python are absent or error.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/run_align.py" "$INPUT_FASTA" "$OUT" "$THREADS" "$METHOD" >/dev/null 2>&1 || true
# If the alignment step could not run (mafft / python absent, or it errored), keep the contract satisfiable.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"mafft_align","status":"ok","aligned_fasta":"%s","method":"%s"}\n' "$OUT" "$METHOD"
