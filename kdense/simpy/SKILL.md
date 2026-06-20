---
skill: simpy
name: SimPy (Discrete-Event Simulation)
perks: [simulate, monitor]
---

# simpy — SimPy (Discrete-Event Simulation)

Run a process-based discrete-event SimPy simulation or a resource-monitoring demo (read-only, file-producing).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
Both perks need the `simpy` package at run time; when it is absent the porter degrades gracefully
(writes a placeholder report and exits 0) so the contract still holds offline.

## Perks
| perk | tool | nature |
|---|---|---|
| `simulate` | `simpy_simulate` | read-only — seeded M/M/c queue simulation, emits `sim_stats.txt` |
| `monitor` | `simpy_monitor` | read-only — resource-monitor demo, emits `monitor_report.txt` |

The `simulate` perk runs the basic queue-simulation template (configurable resources, arrival rate,
service time, horizon, and seed) and reports wait times, service times, and throughput. The `monitor`
perk runs the resource-monitor demo (monkey-patched request/release tracking) and reports time-weighted
utilization, queue length, and wait statistics. Both are deterministic given a fixed seed and never
touch a remote or live service, so both are declared `destructive: false`.

## How to use it
Pick a perk (`simulate` or `monitor`), copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `simpy` — MIT (see LICENSE.txt).
