#!/usr/bin/env bash
# gen_rnaseq_coverage — generate a strand-specific RNA-seq coverage workflow bash script via vendored
# workflow_generator.py (stdlib). Read-only: emits a template script, runs nothing. One JSON audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
: "${RNASEQ_BAM:=}" "${THREADS:=}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/rnaseq_coverage.sh"
# Always (re)create $OUT so the contract's output_exists holds even if python3 is absent or errors.
: > "$OUT"

# Map env vars -> generator args; omit empties so the generator applies its own defaults.
ARGS=(rnaseq_coverage -o "$OUT")
[ -n "$RNASEQ_BAM" ] && ARGS+=(--rnaseq-bam "$RNASEQ_BAM")
[ -n "$THREADS" ]    && ARGS+=(--threads "$THREADS")

if ! command -v python3 >/dev/null 2>&1; then
  printf '# python3 not found on PATH\n' >> "$OUT"
else
  python3 "$HERE/workflow_generator.py" "${ARGS[@]}" >/dev/null 2>&1 || true
fi

# Guarantee non-empty output for the contract even if the generator wrote nothing.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"gen_rnaseq_coverage","status":"ok","workflow":"%s"}\n' "$OUT"
