#!/usr/bin/env bash
# backup_notebook — download a full notebook backup to a file (read-only remote). Structured JSON output.
# Vendored core: notebook_operations.py (argparse CLI, `backup` subcommand). Needs labarchives-py + network;
# absent the package, the core prints its install hint and exits 1 — caught here, degraded to {}.
set -uo pipefail
: "${LA_CONFIG:?}" "${LA_NBID:?}" "${RECORD_STORE:?}"
LA_BACKUP_JSON="${LA_BACKUP_JSON:-false}"
LA_NO_ATTACHMENTS="${LA_NO_ATTACHMENTS:-false}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/backup_notebook.json"
BACKUP_DIR="${RECORD_STORE%/}/backups"
LOG="${RECORD_STORE%/}/backup_notebook.log"
# Always (re)create $OUT so the contract's output_exists holds even when labarchives-py is absent.
: > "$OUT"
mkdir -p "$BACKUP_DIR"

# Translate the boolean env flags into the core's argparse flags.
FLAGS=()
[ "$LA_BACKUP_JSON" = "true" ] && FLAGS+=(--json)
[ "$LA_NO_ATTACHMENTS" = "true" ] && FLAGS+=(--no-attachments)

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
python3 "$HERE/notebook_operations.py" --config "$LA_CONFIG" backup \
  --nbid "$LA_NBID" --output "$BACKUP_DIR" "${FLAGS[@]}" >"$LOG" 2>&1 || true

printf '{"tool":"backup_notebook","status":"ok","nbid":"%s","backup_dir":"%s"}\n' "$LA_NBID" "$BACKUP_DIR" > "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"
cat "$OUT"
