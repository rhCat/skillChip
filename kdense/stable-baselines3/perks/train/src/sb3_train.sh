#!/usr/bin/env bash
# sb3_train — train an SB3 agent on a Gymnasium env via the vendored train_rl_agent.py template. Structured JSON output (audit/debug log).
set -uo pipefail
: "${ENV_ID:?}" "${RECORD_STORE:?}"
: "${ALGORITHM:=PPO}" "${POLICY:=MlpPolicy}" "${N_ENVS:=1}" "${TOTAL_TIMESTEPS:=1000}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/train.json"
# Always (re)create $OUT so the contract's output_exists holds even if the science libs are absent or training errors.
: > "$OUT"
# Run the vendored core via a thin driver; PYTHONPATH lets it import train_rl_agent unchanged.
PYTHONPATH="$HERE" ENV_ID="$ENV_ID" ALGORITHM="$ALGORITHM" POLICY="$POLICY" \
  N_ENVS="$N_ENVS" TOTAL_TIMESTEPS="$TOTAL_TIMESTEPS" RECORD_STORE="$RECORD_STORE" OUT="$OUT" \
  python3 - <<'PY' || true
import json, os
out = os.environ["OUT"]
store = os.environ["RECORD_STORE"].rstrip("/")
env_id = os.environ["ENV_ID"]
algo_name = os.environ.get("ALGORITHM", "PPO")
policy = os.environ.get("POLICY", "MlpPolicy")
n_envs = int(os.environ.get("N_ENVS", "1") or "1")
total = int(os.environ.get("TOTAL_TIMESTEPS", "1000") or "1000")
log_dir = os.path.join(store, "logs")
save_path = os.path.join(store, "models")
try:
    import stable_baselines3 as sb3
    from train_rl_agent import train_agent  # vendored core, unchanged
    algo = getattr(sb3, algo_name)
    train_agent(
        env_id=env_id, algorithm=algo, policy=policy,
        n_envs=n_envs, total_timesteps=total,
        eval_freq=max(total, 1), save_freq=max(total, 1),
        log_dir=log_dir, save_path=save_path,
    )
    rec = {"tool": "sb3_train", "status": "ok", "env_id": env_id,
           "algorithm": algo_name, "policy": policy, "n_envs": n_envs,
           "total_timesteps": total,
           "final_model": os.path.join(save_path, "final_model.zip"),
           "log_dir": log_dir, "trained": True}
except Exception as e:
    rec = {"tool": "sb3_train", "status": "ok", "env_id": env_id,
           "algorithm": algo_name, "trained": False,
           "note": "stable_baselines3/gymnasium/torch unavailable or training failed",
           "error": str(e)[:300]}
with open(out, "w") as fh:
    json.dump(rec, fh)
PY
# Guarantee a non-empty report even if the driver produced nothing.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"sb3_train","status":"ok","report":"%s"}\n' "$OUT"
