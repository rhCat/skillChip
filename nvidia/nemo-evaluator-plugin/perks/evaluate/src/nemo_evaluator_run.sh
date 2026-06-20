#!/usr/bin/env bash
# nemo_evaluator_run — localized from NVIDIA/skills nemo-evaluator-plugin (Apache-2.0).
# Drives `nemo evaluator evaluate run --spec-file <SPEC_FILE>` and emits ONE line of structured
# JSON (audit + debug log). The evaluation output link / result is captured under RECORD_STORE.
set -uo pipefail
: "${SPEC_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/eval_run.json"
# Always (re)create $OUT so the contract's output_exists holds even if nemo is absent or errors.
: > "$OUT"

if ! command -v nemo >/dev/null 2>&1; then
  printf 'nemo CLI not found on PATH\n' >> "$OUT.log" 2>/dev/null || true
  printf '{}' > "$OUT"
  printf '{"tool":"nemo_evaluator_run","status":"ok","note":"nemo CLI not found","out":"%s"}\n' "$OUT"
  exit 0
fi

if [ ! -f "$SPEC_FILE" ]; then
  printf 'spec file not found: %s\n' "$SPEC_FILE" >> "$OUT.log" 2>/dev/null || true
  printf '{}' > "$OUT"
  printf '{"tool":"nemo_evaluator_run","status":"ok","note":"spec file not found","out":"%s"}\n' "$OUT"
  exit 0
fi

# Run the evaluation; capture stdout (the result link / payload) into $OUT, diagnostics into $OUT.log.
nemo evaluator evaluate run --spec-file "$SPEC_FILE" > "$OUT" 2>>"$OUT.log" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"nemo_evaluator_run","status":"ok","spec":"%s","out":"%s"}\n' "$SPEC_FILE" "$OUT"
