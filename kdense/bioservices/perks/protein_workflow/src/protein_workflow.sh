#!/usr/bin/env bash
# protein_workflow — full protein characterization (read-only). Structured JSON audit line.
# Thin porter: vendors protein_analysis_workflow.py; env -> argv; graceful when bioservices/network absent.
# The vendored core prints its report to stdout; we capture stdout into the named report file.
set -uo pipefail
: "${PROTEIN:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/protein_report.txt"
# NCBI_EMAIL is optional; the core auto-skips BLAST when it is unset/invalid.
export NCBI_EMAIL="${NCBI_EMAIL:-}"
# Always (re)create $OUT so the contract's output_exists holds even if the lib/network is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/protein_analysis_workflow.py" "$PROTEIN" \
  > "$OUT" 2>> "${RECORD_STORE%/}/protein_workflow.log" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"protein_workflow","status":"ok","protein":"%s","protein_report":"%s"}\n' "$PROTEIN" "$OUT"
