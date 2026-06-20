#!/usr/bin/env bash
# query_template — search/list venue templates + their formatting requirements (read-only). Structured JSON audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/query.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"

# Translate env vars -> argparse flags for the vendored core.
ARGS=()
if [ -n "${VENUE:-}" ]; then ARGS+=(--venue "$VENUE"); fi
if [ -n "${TEMPLATE_TYPE:-}" ]; then ARGS+=(--type "$TEMPLATE_TYPE"); fi
if [ -n "${KEYWORD:-}" ]; then ARGS+=(--keyword "$KEYWORD"); fi
# If a venue is given, also surface its formatting requirements.
if [ -n "${VENUE:-}" ]; then
  python3 "$HERE/query_template.py" --venue "$VENUE" --requirements >> "$OUT" 2>&1 || true
fi
# No filters at all -> list the whole catalog.
if [ "${#ARGS[@]}" -eq 0 ]; then ARGS+=(--list-all); fi

python3 "$HERE/query_template.py" "${ARGS[@]}" >> "$OUT" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"query_template","status":"ok","venue":"%s","type":"%s","keyword":"%s","out":"%s"}\n' "${VENUE:-}" "${TEMPLATE_TYPE:-}" "${KEYWORD:-}" "$OUT"
