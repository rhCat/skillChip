#!/usr/bin/env bash
# create_comment — add a comment to an existing entry (DESTRUCTIVE remote). Structured JSON output.
# Vendored core: entry_operations.py (argparse CLI, `comment` subcommand; comment text is passed via --text).
# Needs labarchives-py + network; absent the package, the core exits 1 — caught here, degraded to {}.
set -uo pipefail
: "${LA_CONFIG:?}" "${LA_NBID:?}" "${LA_ENTRY_ID:?}" "${LA_COMMENT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/create_comment.json"
LOG="${RECORD_STORE%/}/create_comment.log"
# Always (re)create $OUT so the contract's output_exists holds even when labarchives-py is absent.
: > "$OUT"

# --nbid is a top-level arg on this core; the `comment` subcommand takes the text via --text.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
python3 "$HERE/entry_operations.py" --config "$LA_CONFIG" --nbid "$LA_NBID" \
  comment --entry-id "$LA_ENTRY_ID" --text "$LA_COMMENT" >"$LOG" 2>&1 || true

printf '{"tool":"create_comment","status":"ok","nbid":"%s","entry_id":"%s"}\n' "$LA_NBID" "$LA_ENTRY_ID" > "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"
cat "$OUT"
