#!/usr/bin/env bash
# digest_protein — in-silico protease digestion of FASTA/sequence -> peptide CSV. JSON audit.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/peptides.csv"
: > "$OUT"
if [ -z "${FASTA:-}" ] && [ -z "${SEQUENCE:-}" ]; then
  printf 'digest_protein: set FASTA and/or SEQUENCE\n' >> "$OUT"
  printf '{"tool":"digest_protein","status":"ok","peptides":"%s","note":"no FASTA/SEQUENCE"}\n' "$OUT"
  exit 0
fi
ARGS=()
[ -n "${FASTA:-}" ]      && ARGS+=("$FASTA")
[ -n "${SEQUENCE:-}" ]   && ARGS+=(--sequence "$SEQUENCE")
[ -n "${ENZYME:-}" ]     && ARGS+=(--enzyme "$ENZYME")
[ -n "${MISSED:-}" ]     && ARGS+=(--missed "$MISSED")
[ -n "${MIN_LENGTH:-}" ] && ARGS+=(--min-length "$MIN_LENGTH")
[ -n "${MAX_LENGTH:-}" ] && ARGS+=(--max-length "$MAX_LENGTH")
[ -n "${CHARGES:-}" ]    && ARGS+=(--charges $CHARGES)
ARGS+=(--out "$OUT")
# shellcheck disable=SC2068
python3 "$HERE/digest_protein.py" ${ARGS[@]} > "${RECORD_STORE%/}/digest_protein.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"digest_protein","status":"ok","peptides":"%s"}\n' "$OUT"
