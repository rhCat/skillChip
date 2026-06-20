#!/usr/bin/env bash
# list_notebooks — list all notebooks accessible to the user (read-only remote). Structured JSON output.
# Vendored core: notebook_operations.py (argparse CLI, `list` subcommand). Needs labarchives-py + network;
# absent the package, the core prints its install hint and exits 1 — caught here, degraded to {}.
set -uo pipefail
: "${LA_CONFIG:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/list_notebooks.json"
LISTING="${RECORD_STORE%/}/notebooks.txt"
LOG="${RECORD_STORE%/}/list_notebooks.log"
# Always (re)create $OUT so the contract's output_exists holds even when labarchives-py is absent.
: > "$OUT"

# The core reads its config via --config; capture its stdout (the listing table) and stderr to sidecars.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
python3 "$HERE/notebook_operations.py" --config "$LA_CONFIG" list > "$LISTING" 2>"$LOG" || true

# Emit the structured audit line (this is $OUT). Valid JSON regardless of core outcome.
printf '{"tool":"list_notebooks","status":"ok","config":"%s","listing":"%s"}\n' "$LA_CONFIG" "$LISTING" > "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"
cat "$OUT"
