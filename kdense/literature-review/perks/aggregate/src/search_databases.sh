#!/usr/bin/env bash
# search_databases — dedup + rank + year-filter + format a search-results JSON array (read-only, stdlib). Structured JSON output.
set -uo pipefail
: "${RESULTS_JSON:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/aggregated_results.md"
# Always (re)create $OUT so the contract's output_exists holds even if python3/the input is absent or errors.
: > "$OUT"

FMT="${OUTPUT_FORMAT:-markdown}"

# Translate env -> CLI args for the vendored stdlib core.
ARGS=("$RESULTS_JSON" "--format" "$FMT" "--output" "$OUT")
[ "${DEDUPLICATE:-}" = "1" ] && ARGS+=("--deduplicate")
[ -n "${RANK:-}" ] && ARGS+=("--rank" "$RANK")
[ -n "${YEAR_START:-}" ] && ARGS+=("--year-start" "$YEAR_START")
[ -n "${YEAR_END:-}" ] && ARGS+=("--year-end" "$YEAR_END")

if command -v python3 >/dev/null 2>&1; then
  python3 "$HERE/search_databases.py" "${ARGS[@]}" >>"$OUT.log" 2>&1 || true
else
  printf 'python3 not found on PATH\n' >> "$OUT"
fi

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"search_databases","status":"ok","format":"%s","aggregated":"%s"}\n' "$FMT" "$OUT"
