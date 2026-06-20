#!/usr/bin/env bash
# prepare_demo_assets — localized from NVIDIA/skills physical-ai-video-data-augmentation (Apache-2.0).
# Thin porter: invokes prepare_demo_assets.impl.sh, writes under RECORD_STORE, and ALWAYS creates its
# output (graceful degradation when offline / no HF access). Emits ONE structured-JSON audit line.
set -uo pipefail
: "${DEMO_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/prepared.txt"
# Always (re)create $OUT so the contract's output_exists holds even if HF is unreachable or curl is absent.
: > "$OUT"

status="ok"
bash "$HERE/prepare_demo_assets.impl.sh" "${DEMO_DIR}" >>"$OUT" 2>&1 || status="degraded"
[ -s "$OUT" ] || printf 'prepare_demo_assets produced no output\n' > "$OUT"
printf '{"tool":"prepare_demo_assets","status":"%s","out":"%s"}\n' "$status" "$OUT"
