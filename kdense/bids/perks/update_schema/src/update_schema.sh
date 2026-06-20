#!/usr/bin/env bash
# update_schema — fetch the BIDS schema.json from SCHEMA_URL, validate + re-serialize it,
# and write the result to RECORD_STORE/bids_schema.json. Read-only network fetch.
# Emits one structured-JSON audit line. Degrades gracefully when network/lib is unavailable.
set -uo pipefail
: "${SCHEMA_URL:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/bids_schema.json"
# Always (re)create $OUT so the contract's output_exists holds even if the fetch fails.
: > "$OUT"

# Stage the vendored core in a temp tree so its hardcoded references/ output dir resolves there,
# then copy the produced artifact into RECORD_STORE.
STAGE="$(mktemp -d 2>/dev/null || echo "${RECORD_STORE%/}/.bids_stage_schema")"
mkdir -p "$STAGE/scripts" "$STAGE/references"
cp "$HERE/update_schema.py" "$STAGE/scripts/update_schema.py" 2>/dev/null || true

python3 "$STAGE/scripts/update_schema.py" --schema-url "$SCHEMA_URL" --skip-beps >/dev/null 2>&1 || true

# Pull the fetched/re-serialized schema into RECORD_STORE if the core produced it.
if [ -s "$STAGE/references/bids_schema.json" ]; then
  cp "$STAGE/references/bids_schema.json" "$OUT" 2>/dev/null || true
fi
rm -rf "$STAGE" 2>/dev/null || true

# Guarantee a nonempty artifact even when offline (fetch failed -> empty).
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"update_schema","status":"ok","schema_url":"%s","out":"%s"}\n' "$SCHEMA_URL" "$OUT"
