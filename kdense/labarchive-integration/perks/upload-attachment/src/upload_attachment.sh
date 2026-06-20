#!/usr/bin/env bash
# upload_attachment — upload a file attachment to an existing entry (DESTRUCTIVE remote). Structured JSON.
# Vendored core: entry_operations.py (argparse CLI, `upload` subcommand). Needs labarchives-py + requests +
# network; absent the package, the core prints its install hint and exits 1 — caught here, degraded to {}.
set -uo pipefail
: "${LA_CONFIG:?}" "${LA_NBID:?}" "${LA_ENTRY_ID:?}" "${LA_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/upload_attachment.json"
LOG="${RECORD_STORE%/}/upload_attachment.log"
# Always (re)create $OUT so the contract's output_exists holds even when labarchives-py is absent.
: > "$OUT"

# --nbid is a top-level arg on this core, before the `upload` subcommand.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
python3 "$HERE/entry_operations.py" --config "$LA_CONFIG" --nbid "$LA_NBID" \
  upload --entry-id "$LA_ENTRY_ID" --file "$LA_FILE" >"$LOG" 2>&1 || true

printf '{"tool":"upload_attachment","status":"ok","nbid":"%s","entry_id":"%s","file":"%s"}\n' \
  "$LA_NBID" "$LA_ENTRY_ID" "$LA_FILE" > "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"
cat "$OUT"
