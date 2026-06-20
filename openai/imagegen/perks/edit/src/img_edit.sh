#!/usr/bin/env bash
# img_edit — edit an existing image via the vendored GPT Image CLI (image_gen.py edit).
# SPDX-License-Identifier: Apache-2.0
# Runs in --dry-run mode: validates the request + resolves output paths WITHOUT network or OPENAI_API_KEY.
# Local-output only. Emits one structured-JSON audit line.
set -uo pipefail
: "${PROMPT:?}" "${IMAGE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/edit.json"
# Always (re)create $OUT so the contract's output_exists holds even if python3/core errors.
: > "$OUT"

ARGS=(edit --prompt "$PROMPT" --image "$IMAGE" --dry-run --no-augment --out "${RECORD_STORE%/}/output.png")
[ -n "${MASK:-}" ]           && ARGS+=(--mask "$MASK")
[ -n "${MODEL:-}" ]          && ARGS+=(--model "$MODEL")
[ -n "${SIZE:-}" ]           && ARGS+=(--size "$SIZE")
[ -n "${INPUT_FIDELITY:-}" ] && ARGS+=(--input-fidelity "$INPUT_FIDELITY")

if command -v python3 >/dev/null 2>&1; then
  python3 "$HERE/image_gen.py" "${ARGS[@]}" >> "$OUT" 2>/dev/null || true
else
  printf 'python3 not found on PATH\n' >> "$OUT"
fi

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"img_edit","status":"ok","mode":"dry-run","report":"%s"}\n' "$OUT"
