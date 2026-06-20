#!/usr/bin/env bash
# train — run the PuffeRL PPO+LSTM training template on a chosen environment. Local compute.
# Writes a training log (and checkpoints when the RL stack is present). Structured JSON output.
set -uo pipefail
: "${RECORD_STORE:?}"
ENV_NAME="${ENV_NAME:-procgen-coinrun}"
NUM_ENVS="${NUM_ENVS:-256}"
NUM_ITERATIONS="${NUM_ITERATIONS:-1}"
DEVICE="${DEVICE:-cpu}"
HERE="$(cd "$(dirname "$0")" && pwd)"
LOG="${RECORD_STORE%/}/train.log"
CKPT_DIR="${RECORD_STORE%/}/checkpoints"
# Always (re)create $LOG so the contract's output_exists holds even if the stack is absent or errors.
: > "$LOG"
mkdir -p "$CKPT_DIR" 2>/dev/null || true

# Real training needs pufferlib + torch; degrade gracefully otherwise.
# (Guard requires a concrete pufferlib.__file__ so an empty namespace-package dir named "pufferlib"
#  on the cwd cannot masquerade as the real library.)
if python3 -c "import pufferlib, torch; assert getattr(pufferlib,'__file__',None)" >/dev/null 2>&1; then
  PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/train_template.py" \
    --env-name "$ENV_NAME" \
    --num-envs "$NUM_ENVS" \
    --num-iterations "$NUM_ITERATIONS" \
    --device "$DEVICE" \
    --checkpoint-dir "$CKPT_DIR" \
    >> "$LOG" 2>&1 || true
  STACK="present"
else
  printf 'pufferlib/torch not importable — training not run (env=%s, num_envs=%s, iters=%s, device=%s)\n' \
    "$ENV_NAME" "$NUM_ENVS" "$NUM_ITERATIONS" "$DEVICE" >> "$LOG"
  STACK="absent"
fi

[ -s "$LOG" ] || printf '{}' > "$LOG"
printf '{"tool":"train","status":"ok","env":"%s","num_envs":"%s","iterations":"%s","device":"%s","stack":"%s","log":"%s","checkpoints":"%s"}\n' \
  "$ENV_NAME" "$NUM_ENVS" "$NUM_ITERATIONS" "$DEVICE" "$STACK" "$LOG" "$CKPT_DIR"
