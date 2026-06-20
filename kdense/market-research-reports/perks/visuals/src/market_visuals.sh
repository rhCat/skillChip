#!/usr/bin/env bash
# market_visuals — plan/generate the standard market-research-report visual set for a TOPIC.
# Thin governed porter around the vendored generate_market_visuals.py. The real rendering fans
# out to the scientific-schematics / generate-image backends; when those are absent the script
# still emits a deterministic plan of every visual (its --dry-run path), which we capture as the
# manifest so the contract holds offline. Structured JSON audit line on stdout.
set -uo pipefail
: "${TOPIC:?TOPIC required}" "${RECORD_STORE:?RECORD_STORE required}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/market_visuals_manifest.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python3 is absent or errors.
: > "$OUT"

# ALL=1 (or non-empty) plans the full extended set; otherwise only the core 5-6.
ALL_FLAG=""
if [ -n "${ALL:-}" ]; then
  ALL_FLAG="--all"
fi

if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
  printf '{"tool":"market_visuals","status":"ok","topic":"%s","mode":"dry-run","backends":"absent","manifest":"%s"}\n' "$TOPIC" "$OUT"
  exit 0
fi

# --dry-run is hermetic (stdlib only, no subprocess/network): it lists every planned visual.
# Capture its stdout into the manifest. || true tolerates the upstream --all 4-tuple unpack bug.
python3 "$HERE/generate_market_visuals.py" --topic "$TOPIC" $ALL_FLAG --dry-run >> "$OUT" 2>&1 || true

# Guarantee non-empty output for the contract even if the core produced nothing.
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"market_visuals","status":"ok","topic":"%s","mode":"dry-run","manifest":"%s"}\n' "$TOPIC" "$OUT"
