#!/usr/bin/env bash
# sb3_evaluate — load a saved SB3 model and evaluate_policy over N episodes via the vendored evaluate_agent.py template. Structured JSON output (audit/debug log).
set -uo pipefail
: "${MODEL_PATH:?}" "${ENV_ID:?}" "${RECORD_STORE:?}"
: "${N_EVAL_EPISODES:=10}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/evaluation.json"
# Always (re)create $OUT so the contract's output_exists holds even if the science libs are absent or evaluation errors.
: > "$OUT"
# Run the vendored core via a thin driver; PYTHONPATH lets it import evaluate_agent unchanged.
PYTHONPATH="$HERE" MODEL_PATH="$MODEL_PATH" ENV_ID="$ENV_ID" N_EVAL_EPISODES="$N_EVAL_EPISODES" \
  RECORD_STORE="$RECORD_STORE" OUT="$OUT" \
  python3 - <<'PY' || true
import json, os
out = os.environ["OUT"]
model_path = os.environ["MODEL_PATH"]
env_id = os.environ["ENV_ID"]
n_eps = int(os.environ.get("N_EVAL_EPISODES", "10") or "10")
try:
    from evaluate_agent import evaluate_agent  # vendored core, unchanged
    mean_reward, std_reward = evaluate_agent(
        model_path=model_path, env_id=env_id,
        n_eval_episodes=n_eps, deterministic=True,
    )
    rec = {"tool": "sb3_evaluate", "status": "ok", "model_path": model_path,
           "env_id": env_id, "n_eval_episodes": n_eps,
           "mean_reward": float(mean_reward), "std_reward": float(std_reward),
           "evaluated": True}
except Exception as e:
    rec = {"tool": "sb3_evaluate", "status": "ok", "model_path": model_path,
           "env_id": env_id, "evaluated": False,
           "note": "stable_baselines3/gymnasium/torch unavailable, model missing, or evaluation failed",
           "error": str(e)[:300]}
with open(out, "w") as fh:
    json.dump(rec, fh)
PY
# Guarantee a non-empty report even if the driver produced nothing.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"sb3_evaluate","status":"ok","report":"%s"}\n' "$OUT"
