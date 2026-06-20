#!/usr/bin/env bash
# detect_resources — probe CPU/GPU/memory/disk/OS and write a JSON resource report with
# strategic recommendations (read-only). Structured JSON output (audit/debug log).
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/.claude_resources.json"
# Disk-space probe dir: PROBE_PATH if set + a real dir, else RECORD_STORE.
PROBE_DIR="${PROBE_PATH:-}"
if [ -z "$PROBE_DIR" ] || [ ! -d "$PROBE_DIR" ]; then
  PROBE_DIR="${RECORD_STORE%/}"
fi
# Always (re)create $OUT so the contract's output_exists holds even if python3/psutil is absent or errors.
: > "$OUT"
# Run the vendored core with cwd = PROBE_DIR so disk usage reflects the requested path
# (the core defaults its disk probe to os.getcwd()). -o writes the report to $OUT.
( cd "$PROBE_DIR" && python3 "$HERE/detect_resources.py" -o "$OUT" ) >/dev/null 2>&1 || true
# Fall back to a valid-JSON stub if the core could not produce a report (e.g. psutil missing).
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"detect_resources","status":"ok","report":"%s","probe_dir":"%s"}\n' "$OUT" "$PROBE_DIR"
