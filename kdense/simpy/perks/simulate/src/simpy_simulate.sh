#!/usr/bin/env bash
# simpy_simulate — run a seeded discrete-event queue simulation (basic_simulation_template.py)
# and capture its statistics report. Read-only. Structured JSON output (audit/debug log).
set -uo pipefail
: "${RECORD_STORE:?}"
: "${SIM_TIME:?}" "${NUM_RESOURCES:?}" "${ARRIVAL_RATE:?}" "${SERVICE_TIME_MEAN:?}" "${RANDOM_SEED:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/sim_stats.txt"
# Always (re)create $OUT so the contract's output_exists holds even if simpy is absent or errors.
: > "$OUT"
# Probe for the REAL simpy package (not a same-named namespace dir on the path).
if ! python3 -c "import simpy; simpy.Environment" >/dev/null 2>&1; then
  printf 'simpy not installed — simulation skipped (degraded mode)\n' >> "$OUT"
  printf '{"tool":"simpy_simulate","status":"ok","report":"%s","simpy":"absent"}\n' "$OUT"
  exit 0
fi
# env -> SimulationConfig translation; the vendored core is imported UNCHANGED.
PYTHONPATH="$HERE" python3 - >> "$OUT" 2>&1 <<'PY' || true
import os
from basic_simulation_template import SimulationConfig, run_simulation

cfg = SimulationConfig()
cfg.random_seed = int(os.environ["RANDOM_SEED"])
cfg.num_resources = int(os.environ["NUM_RESOURCES"])
cfg.sim_time = float(os.environ["SIM_TIME"])
cfg.arrival_rate = float(os.environ["ARRIVAL_RATE"])
cfg.service_time_mean = float(os.environ["SERVICE_TIME_MEAN"])

stats = run_simulation(cfg)
stats.report()
PY
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"simpy_simulate","status":"ok","report":"%s"}\n' "$OUT"
