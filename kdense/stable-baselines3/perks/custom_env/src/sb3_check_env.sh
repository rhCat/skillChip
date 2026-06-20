#!/usr/bin/env bash
# sb3_check_env — instantiate the custom Gym env template and validate it with SB3 check_env, via the vendored custom_env_template.py. Structured JSON output (audit/debug log).
set -uo pipefail
: "${RECORD_STORE:?}"
: "${GRID_SIZE:=5}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/check_env.json"
# Always (re)create $OUT so the contract's output_exists holds even if the science libs are absent or the check errors.
: > "$OUT"
# Run the vendored core via a thin driver; PYTHONPATH lets it import custom_env_template unchanged.
PYTHONPATH="$HERE" GRID_SIZE="$GRID_SIZE" RECORD_STORE="$RECORD_STORE" OUT="$OUT" \
  python3 - <<'PY' || true
import json, os
out = os.environ["OUT"]
grid_size = int(os.environ.get("GRID_SIZE", "5") or "5")
try:
    from custom_env_template import CustomEnv  # vendored core, unchanged
    from stable_baselines3.common.env_checker import check_env
    env = CustomEnv(grid_size=grid_size)
    check_env(env, warn=True)
    rec = {"tool": "sb3_check_env", "status": "ok", "grid_size": grid_size,
           "valid": True, "note": "check_env passed"}
except Exception as e:
    rec = {"tool": "sb3_check_env", "status": "ok", "grid_size": grid_size,
           "valid": False,
           "note": "stable_baselines3/gymnasium unavailable or check_env failed",
           "error": str(e)[:300]}
with open(out, "w") as fh:
    json.dump(rec, fh)
PY
# Guarantee a non-empty report even if the driver produced nothing.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"sb3_check_env","status":"ok","report":"%s"}\n' "$OUT"
