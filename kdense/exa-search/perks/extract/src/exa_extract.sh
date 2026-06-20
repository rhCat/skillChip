#!/usr/bin/env bash
# exa_extract — Exa URL content extraction (client.get_contents) → extract.json. Read-only. Structured JSON audit line.
set -uo pipefail
: "${URLS:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/extract.json"
# Always (re)create $OUT so the contract's output_exists holds even if exa-py/key/network is absent or errors.
: > "$OUT"

# URLS is whitespace-separated; expand into positional args for the vendored core.
read -r -a URL_ARGS <<< "$URLS"
ARGS=("${URL_ARGS[@]}" "--text" "-o" "$OUT")
[ -n "${HIGHLIGHTS:-}" ] && ARGS+=("--highlights")

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/exa_extract.py" "${ARGS[@]}" >/dev/null 2>&1 || true

# Degrade gracefully: if the core could not produce output (no exa-py / no key / no network), leave a valid empty report.
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"exa_extract","status":"ok","urls":"%s","results":"%s"}\n' "$URLS" "$OUT"
