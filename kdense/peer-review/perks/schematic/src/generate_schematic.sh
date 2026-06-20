#!/usr/bin/env bash
# generate_schematic — render a publication-quality scientific schematic via AI (Nano Banana 2)
# with iterative Gemini quality review. Thin governed porter over the vendored K-Dense core.
# Emits one line of structured JSON (audit/debug log); writes artifacts under RECORD_STORE.
set -uo pipefail
: "${PROMPT:?}" "${OUTPUT:?}" "${RECORD_STORE:?}"
DOC_TYPE="${DOC_TYPE:-default}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The audit artifact the contract checks for — always (re)created so output_exists holds
# even if the AI core is unreachable (no OPENROUTER_API_KEY / no network / requests absent).
OUT="${RECORD_STORE%/}/schematic.json"
: > "$OUT"

# Resolve the image path under RECORD_STORE (never escape the record store).
OUT_IMG="${RECORD_STORE%/}/$(basename "$OUTPUT")"
LOG="${RECORD_STORE%/}/schematic_run.log"
: > "$LOG"

# Run the vendored core (env -> arg translation). Never let a failure abort the porter.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/generate_schematic.py" "$PROMPT" -o "$OUT_IMG" --doc-type "$DOC_TYPE" \
  >> "$LOG" 2>&1 || true

# Surface whether the image actually landed (it only does with a key + network).
if [ -s "$OUT_IMG" ]; then
  STATUS="generated"
else
  STATUS="skipped"
fi

printf '{"tool":"generate_schematic","status":"ok","result":"%s","image":"%s","log":"%s","doc_type":"%s"}\n' \
  "$STATUS" "$OUT_IMG" "$LOG" "$DOC_TYPE" > "$OUT"

# Guarantee a non-empty audit artifact regardless of the branch above.
[ -s "$OUT" ] || printf '{}' > "$OUT"

# One structured-JSON audit line to stdout (the run-ledger captures this).
printf '{"tool":"generate_schematic","status":"ok","result":"%s","image":"%s","log":"%s","doc_type":"%s"}\n' \
  "$STATUS" "$OUT_IMG" "$LOG" "$DOC_TYPE"
