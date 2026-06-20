---
skill: get-available-resources
name: Get Available Resources
perks: [detect]
---

# get-available-resources — Get Available Resources

Detect available compute resources (CPU/GPU/memory/disk) and emit a JSON report with strategic recommendations (read-only).

## What to look out for
The tool emits one line of structured JSON (the audit + debug log) and writes its artifact under
`record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `detect` | `detect_resources` | read-only / safe (probes CPU, GPU, memory, disk, OS; writes `.claude_resources.json`) |

The `detect` perk runs `detect_resources.py` once: it reads CPU/logical-core counts and frequency
(psutil), memory + swap (psutil), disk usage for the probe path (psutil), GPU presence (nvidia-smi /
rocm-smi / Apple `sysctl`+`system_profiler`), and OS/Python info, then derives parallel-processing,
memory, GPU, and large-data recommendations. All of that is a single detection pass with one
JSON output — not separable into independent operations — so it is one perk. It only reads system
state and writes one report; nothing is mutated, hence `destructive: false`.

## How to use it
Pick the `detect` perk, copy `ledger.json` → `task-ledger.json`, fill `record_store` (and optionally
`PROBE_PATH`), then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `get-available-resources` — MIT (see LICENSE.txt).
