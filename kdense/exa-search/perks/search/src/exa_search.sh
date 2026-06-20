#!/usr/bin/env bash
# exa_search — Exa web search (client.search_and_contents) → search.json. Read-only. Structured JSON audit line.
set -uo pipefail
: "${QUERY:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/search.json"
# Always (re)create $OUT so the contract's output_exists holds even if exa-py/key/network is absent or errors.
: > "$OUT"

# Translate env -> CLI args for the vendored core.
ARGS=("$QUERY" "--text" "--highlights" "-o" "$OUT")
[ -n "${SEARCH_TYPE:-}" ]     && ARGS+=("--type" "$SEARCH_TYPE")
[ -n "${NUM_RESULTS:-}" ]     && ARGS+=("--num-results" "$NUM_RESULTS")
[ -n "${CATEGORY:-}" ]        && ARGS+=("--category" "$CATEGORY")
[ -n "${INCLUDE_DOMAINS:-}" ] && ARGS+=("--include-domains" "$INCLUDE_DOMAINS")
[ -n "${EXCLUDE_DOMAINS:-}" ] && ARGS+=("--exclude-domains" "$EXCLUDE_DOMAINS")

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/exa_search.py" "${ARGS[@]}" >/dev/null 2>&1 || true

# Degrade gracefully: if the core could not produce output (no exa-py / no key / no network), leave a valid empty report.
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"exa_search","status":"ok","query":"%s","results":"%s"}\n' "$QUERY" "$OUT"
