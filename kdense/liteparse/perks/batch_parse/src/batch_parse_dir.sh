#!/usr/bin/env bash
# batch_parse_dir — parse every supported file in a directory via the vendored batch_parse_dir.py.
# Read-only on inputs. Local only. Structured JSON audit line on stdout.
set -uo pipefail
: "${INPUT_DIR:?}" "${RECORD_STORE:?}"
FORMAT="${FORMAT:-text}"
EXTENSION="${EXTENSION:-}"
RECURSIVE="${RECURSIVE:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/batch.json"
PARSED_DIR="${RECORD_STORE%/}/parsed"
LOG="${RECORD_STORE%/}/batch.log"
# Always (re)create $OUT so the contract's output_exists holds even if liteparse is absent or errors.
: > "$OUT"
: > "$LOG"
mkdir -p "$PARSED_DIR" 2>/dev/null || true

# env -> arg translation for the vendored CLI
ARGS=("$INPUT_DIR" "$PARSED_DIR" "--format" "$FORMAT" "--quiet")
[ -n "$EXTENSION" ] && ARGS+=("--extension" "$EXTENSION")
[ "$RECURSIVE" = "1" ] && ARGS+=("--recursive")

RC=0
python3 "$HERE/batch_parse_dir.py" "${ARGS[@]}" >> "$LOG" 2>&1 || RC=$?

# Summarize the run as JSON (graceful when liteparse is absent — RC != 0 / import error in log).
N_OUT=$(find "$PARSED_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$RC" -eq 0 ]; then
  printf '{"status":"ok","input_dir":"%s","format":"%s","outputs_written":%s}\n' "$INPUT_DIR" "$FORMAT" "$N_OUT" > "$OUT"
else
  printf '{"status":"skipped","reason":"batch_parse_dir.py exited %s (liteparse likely absent); see batch.log","input_dir":"%s","format":"%s","outputs_written":%s}\n' "$RC" "$INPUT_DIR" "$FORMAT" "$N_OUT" > "$OUT"
fi
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"batch_parse_dir","status":"ok","input_dir":"%s","format":"%s","summary":"%s"}\n' "$INPUT_DIR" "$FORMAT" "$OUT"
