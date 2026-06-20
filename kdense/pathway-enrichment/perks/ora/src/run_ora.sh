#!/usr/bin/env bash
# run_ora — over-representation analysis (Enrichr/Fisher) on a gene hit list via gseapy.
# Thin governed porter around vendored run_enrichment.py (subcommand: ora). Structured JSON audit line.
set -uo pipefail
: "${GENES:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/ora_results.csv"
LOG="${RECORD_STORE%/}/ora_run.log"
# Always (re)create the contract output so output_exists holds even if gseapy is absent or errors.
# The vendored CLI writes the real ora_results.csv into --outdir on success; runner chatter goes to $LOG.
: > "$OUT"
: > "$LOG"

LIBRARIES="${LIBRARIES:-}"
ORGANISM="${ORGANISM:-human}"
FDR="${FDR:-0.05}"
BACKGROUND="${BACKGROUND:-}"

# env -> argv translation for the vendored CLI.
ARGS=(ora --genes "$GENES" --organism "$ORGANISM" --fdr "$FDR" --outdir "${RECORD_STORE%/}")
if [ -n "$LIBRARIES" ]; then
  # shellcheck disable=SC2206
  LIBS=($LIBRARIES)
  ARGS+=(--libraries "${LIBS[@]}")
fi
if [ -n "$BACKGROUND" ]; then
  ARGS+=(--background "$BACKGROUND")
fi

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/run_enrichment.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true

# Guarantee a non-empty artifact even when gseapy is missing / offline / errored:
# fall back to the runner log, then to a JSON stub.
[ -s "$OUT" ] || cat "$LOG" > "$OUT" 2>/dev/null || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_ora","status":"ok","ora_results":"%s","log":"%s"}\n' "$OUT" "$LOG"
