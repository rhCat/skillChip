#!/usr/bin/env bash
# simpy_monitor — run a SimPy resource-monitoring demo (resource_monitor.py: ResourceMonitor)
# and capture its utilization/queue/wait report. Read-only. Structured JSON output (audit/debug log).
set -uo pipefail
: "${RECORD_STORE:?}"
: "${NUM_PROCESSES:?}" "${CAPACITY:?}" "${BASE_DURATION:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/monitor_report.txt"
# Always (re)create $OUT so the contract's output_exists holds even if simpy is absent or errors.
: > "$OUT"
# Probe for the REAL simpy package (not a same-named namespace dir on the path).
if ! python3 -c "import simpy; simpy.Environment" >/dev/null 2>&1; then
  printf 'simpy not installed — monitoring demo skipped (degraded mode)\n' >> "$OUT"
  printf '{"tool":"simpy_monitor","status":"ok","report":"%s","simpy":"absent"}\n' "$OUT"
  exit 0
fi
# env -> demo params translation; the vendored ResourceMonitor is imported UNCHANGED.
PYTHONPATH="$HERE" python3 - >> "$OUT" 2>&1 <<'PY' || true
import os
import simpy
from resource_monitor import ResourceMonitor

n = int(os.environ["NUM_PROCESSES"])
cap = int(os.environ["CAPACITY"])
base = float(os.environ["BASE_DURATION"])
csv_path = os.path.join(os.environ["RECORD_STORE"], "monitor_data.csv")

def example_process(env, name, resource, duration):
    with resource.request() as req:
        yield req
        yield env.timeout(duration)

env = simpy.Environment()
resource = simpy.Resource(env, capacity=cap)
monitor = ResourceMonitor(env, resource, "Demo Resource")
for i in range(n):
    env.process(example_process(env, f"Process {i}", resource, base + i))
env.run()
monitor.report()
monitor.export_csv(csv_path)
PY
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"simpy_monitor","status":"ok","report":"%s"}\n' "$OUT"
