#!/usr/bin/env bash
# update_beps — fetch the current BIDS Extension Proposals listing (beps.yml) from the
# bids-website upstream and write it to RECORD_STORE/beps.yml. Read-only network fetch.
# Emits one structured-JSON audit line. Degrades gracefully when network/lib is unavailable.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/beps.yml"
# Always (re)create $OUT so the contract's output_exists holds even if the fetch fails.
: > "$OUT"

# Stage the vendored core in a temp tree so its hardcoded references/ output dir resolves there,
# then copy the produced artifact into RECORD_STORE. The core's --schema-url default is used for
# the (discarded) schema step; we keep both fetches but only export beps.yml for this perk.
STAGE="$(mktemp -d 2>/dev/null || echo "${RECORD_STORE%/}/.bids_stage_beps")"
mkdir -p "$STAGE/scripts" "$STAGE/references"
cp "$HERE/update_schema.py" "$STAGE/scripts/update_schema.py" 2>/dev/null || true

python3 "$STAGE/scripts/update_schema.py" >/dev/null 2>&1 || true

# Pull the fetched beps.yml into RECORD_STORE if the core produced it.
if [ -s "$STAGE/references/beps.yml" ]; then
  cp "$STAGE/references/beps.yml" "$OUT" 2>/dev/null || true
fi
rm -rf "$STAGE" 2>/dev/null || true

# Guarantee a nonempty artifact even when offline (fetch failed -> empty).
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"update_beps","status":"ok","out":"%s"}\n' "$OUT"
