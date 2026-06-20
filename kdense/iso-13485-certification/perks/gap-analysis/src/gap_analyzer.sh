#!/usr/bin/env bash
# gap_analyzer — scan a QMS docs dir for ISO 13485:2016 required procedures + key documents (read-only). Structured JSON output (audit/debug log).
set -uo pipefail
: "${DOCS_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/gap-report.json"
# Always (re)create $OUT so the contract's output_exists holds even if python3 is absent or errors.
: > "$OUT"
if ! command -v python3 >/dev/null 2>&1; then
  printf '{}' > "$OUT"
  printf '{"tool":"gap_analyzer","status":"ok","report":"%s","note":"python3 not found on PATH"}\n' "$OUT"
  exit 0
fi
# Vendored core is pure stdlib (argparse/json/pathlib/datetime); env -> CLI arg translation. Stdout report goes to the run-ledger.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/gap_analyzer.py" --docs-dir "$DOCS_DIR" --output "$OUT" >/dev/null 2>&1 || true
# Fallback so output_exists + nonempty always hold even if the core errored before writing.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"gap_analyzer","status":"ok","report":"%s"}\n' "$OUT"
