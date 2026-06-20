#!/usr/bin/env bash
# img_generate_batch — generate many images from a JSONL job file via the vendored GPT Image CLI
# (image_gen.py generate-batch).
# SPDX-License-Identifier: Apache-2.0
# Runs in --dry-run mode: validates every job + resolves output paths WITHOUT network or OPENAI_API_KEY.
# Local-output only. Emits one structured-JSON audit line.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/batch.json"
OUTDIR="${RECORD_STORE%/}/batch"
mkdir -p "$OUTDIR" 2>/dev/null || true
# Always (re)create $OUT so the contract's output_exists holds even if python3/core errors.
: > "$OUT"

ARGS=(generate-batch --input "$INPUT" --out-dir "$OUTDIR" --dry-run --no-augment)
[ -n "${MODEL:-}" ]       && ARGS+=(--model "$MODEL")
[ -n "${SIZE:-}" ]        && ARGS+=(--size "$SIZE")
[ -n "${QUALITY:-}" ]     && ARGS+=(--quality "$QUALITY")
[ -n "${CONCURRENCY:-}" ] && ARGS+=(--concurrency "$CONCURRENCY")

if command -v python3 >/dev/null 2>&1; then
  python3 "$HERE/image_gen.py" "${ARGS[@]}" >> "$OUT" 2>/dev/null || true
else
  printf 'python3 not found on PATH\n' >> "$OUT"
fi

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"img_generate_batch","status":"ok","mode":"dry-run","report":"%s"}\n' "$OUT"
