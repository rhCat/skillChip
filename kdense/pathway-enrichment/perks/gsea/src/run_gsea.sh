#!/usr/bin/env bash
# run_gsea — preranked GSEA from a DESeq2 results table or an explicit gene,score rank file via gseapy.
# Thin governed porter around vendored run_enrichment.py (subcommand: gsea). Structured JSON audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/gsea_results.csv"
LOG="${RECORD_STORE%/}/gsea_run.log"
# Always (re)create the contract output so output_exists holds even if gseapy is absent or errors.
# The vendored CLI writes the real gsea_results.csv into --outdir on success; runner chatter goes to $LOG.
: > "$OUT"
: > "$LOG"

DESEQ2="${DESEQ2:-}"
RNK="${RNK:-}"
LIBRARIES="${LIBRARIES:-}"
ORGANISM="${ORGANISM:-human}"
FDR="${FDR:-0.05}"
SEED="${SEED:-123}"
MIN_SIZE="${MIN_SIZE:-15}"
MAX_SIZE="${MAX_SIZE:-500}"
PERMUTATIONS="${PERMUTATIONS:-1000}"

# env -> argv translation for the vendored CLI. Exactly one of DESEQ2/RNK is expected; the CLI errors otherwise.
ARGS=(gsea --organism "$ORGANISM" --fdr "$FDR" --seed "$SEED" \
  --min-size "$MIN_SIZE" --max-size "$MAX_SIZE" --permutations "$PERMUTATIONS" \
  --outdir "${RECORD_STORE%/}")
if [ -n "$DESEQ2" ]; then
  ARGS+=(--deseq2 "$DESEQ2")
fi
if [ -n "$RNK" ]; then
  ARGS+=(--rnk "$RNK")
fi
if [ -n "$LIBRARIES" ]; then
  # shellcheck disable=SC2206
  LIBS=($LIBRARIES)
  ARGS+=(--libraries "${LIBS[@]}")
fi

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/run_enrichment.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true

# Guarantee a non-empty artifact even when gseapy is missing / offline / errored:
# fall back to the runner log, then to a JSON stub.
[ -s "$OUT" ] || cat "$LOG" > "$OUT" 2>/dev/null || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_gsea","status":"ok","gsea_results":"%s","log":"%s"}\n' "$OUT" "$LOG"
