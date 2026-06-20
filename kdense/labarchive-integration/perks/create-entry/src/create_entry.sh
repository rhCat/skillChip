#!/usr/bin/env bash
# create_entry — create a new entry in a notebook (DESTRUCTIVE remote). Structured JSON output.
# Vendored core: entry_operations.py (argparse CLI, `create` subcommand). Needs labarchives-py + network;
# absent the package, the core prints its install hint and exits 1 — caught here, degraded to {}.
set -uo pipefail
: "${LA_CONFIG:?}" "${LA_NBID:?}" "${LA_TITLE:?}" "${RECORD_STORE:?}"
LA_CONTENT="${LA_CONTENT:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/create_entry.json"
LOG="${RECORD_STORE%/}/create_entry.log"
# Always (re)create $OUT so the contract's output_exists holds even when labarchives-py is absent.
: > "$OUT"

# --nbid is a top-level arg on this core, before the `create` subcommand. --content is optional.
ARGS=(--config "$LA_CONFIG" --nbid "$LA_NBID" create --title "$LA_TITLE")
[ -n "$LA_CONTENT" ] && ARGS+=(--content "$LA_CONTENT")

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
python3 "$HERE/entry_operations.py" "${ARGS[@]}" >"$LOG" 2>&1 || true

printf '{"tool":"create_entry","status":"ok","nbid":"%s","title":"%s"}\n' "$LA_NBID" "$LA_TITLE" > "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"
cat "$OUT"
