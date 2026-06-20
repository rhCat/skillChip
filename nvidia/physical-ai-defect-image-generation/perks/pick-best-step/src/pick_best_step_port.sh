#!/usr/bin/env bash
# pick_best_step_port — localized from NVIDIA/skills physical-ai-defect-image-generation (Apache-2.0).
# Governed entry point: derive the best anomalygen inference step from a checkpoint
# tree (argmax avg nn_score among validated steps with a saved iter_*.pt; falls back
# to the latest trained iter, then to the supplied fallback). Pure filesystem walk —
# fully offline. Emits ONE line of structured JSON on stdout and ALWAYS creates its
# output file (graceful degradation, like terraform's tf_plan.sh).
set -uo pipefail
: "${CKPT_ROOT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/best_step.txt"
# Always (re)create $OUT so the contract's output_exists holds even on a degraded path.
: > "$OUT"

FALLBACK="${FALLBACK_STEP:-0}"
# Core echoes the chosen step on stdout; stderr is the human rationale. Tee both.
bash "$HERE/pick_best_step.sh" "$CKPT_ROOT" "$FALLBACK" >"$OUT" 2>>"$OUT.log" || true
[ -s "$OUT" ] || printf '%s\n' "$FALLBACK" > "$OUT"
STEP="$(tr -d '[:space:]' < "$OUT")"
printf '{"tool":"pick_best_step","status":"ok","step":"%s","out":"%s"}\n' "$STEP" "$OUT"
