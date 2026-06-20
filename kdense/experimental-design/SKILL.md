---
skill: experimental-design
name: Experimental Design (DOE & randomization)
perks: [simple-randomization, block-randomization, stratified-block-randomization, cluster-randomization, assign-factorial-runs, full-factorial, two-level-factorial, fractional-factorial, plackett-burman, central-composite, box-behnken, latin-hypercube]
---

# experimental-design — Experimental Design (DOE & randomization)

Generate seeded randomization/allocation schedules and design-of-experiments matrices (read-only, local). Each perk reads a small JSON spec and writes a reproducible CSV layout under `record_store`.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under `record_store`. LOGS TO CHECK: that line + the named CSV + the executor run-ledger. Every layout is seeded, so the exact schedule/matrix can be archived and regenerated (a requirement for trial registration and good lab practice).

The randomization perks (`simple-`, `block-`, `stratified-block-`, `cluster-randomization`, `assign-factorial-runs`) need only numpy + pandas. The DOE-matrix perks (`full-`, `two-level-`, `fractional-factorial`, `plackett-burman`, `central-composite`, `box-behnken`, `latin-hypercube`) additionally require `pyDOE3`; when it is absent the porter writes a graceful empty `{}` artifact rather than failing.

## Perks
| perk | tool | nature |
|---|---|---|
| `simple-randomization` | `simple_randomization` | read-only — independent per-unit assignment (numpy/pandas) |
| `block-randomization` | `block_randomization` | read-only — permuted blocks, balance throughout (numpy/pandas) |
| `stratified-block-randomization` | `stratified_block_randomization` | read-only — blocks within strata (numpy/pandas) |
| `cluster-randomization` | `cluster_randomization` | read-only — randomize whole clusters (numpy/pandas) |
| `assign-factorial-runs` | `assign_factorial_runs` | read-only — randomize run order of design rows (numpy/pandas) |
| `full-factorial` | `full_factorial` | read-only — full factorial over explicit levels (pyDOE3) |
| `two-level-factorial` | `two_level_factorial` | read-only — full 2^k factorial (pyDOE3) |
| `fractional-factorial` | `fractional_factorial` | read-only — 2^(k-p) from a generator (pyDOE3) |
| `plackett-burman` | `plackett_burman` | read-only — main-effects screening (pyDOE3) |
| `central-composite` | `central_composite` | read-only — response-surface CCD (pyDOE3) |
| `box-behnken` | `box_behnken` | read-only — response-surface BBD, >=3 factors (pyDOE3) |
| `latin-hypercube` | `latin_hypercube` | read-only — space-filling sample (pyDOE3) |

All perks are `destructive: false`: they read a JSON spec and write a CSV; nothing mutates a remote or live service.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `experimental-design` — MIT (see LICENSE.txt).
