---
skill: statistical-power
name: Statistical Power & Sample Size
perks: [sample_size, achieved_power, mde, power_curve, simulate_power]
---

# statistical-power — Statistical Power & Sample Size

Closed-form and simulation-based power, sample-size, MDE, and power-curve calculations for study planning (read-only).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report (`*.json`,
plus `power_curve.png` for the curve) + the executor run-ledger. Power calculations
are only as trustworthy as the effect size fed in — supply a defensible effect (SESOI >
shrunk pilot > convention), never an invented one, and never report post-hoc / observed power.

## Perks
| perk | tool | nature |
|---|---|---|
| `sample_size` | `power_sample_size` | read-only — solve required n for a given effect, alpha, power |
| `achieved_power` | `power_achieved` | read-only — solve power (1-β) at a fixed n and effect |
| `mde` | `power_mde` | read-only — minimum detectable effect at a fixed n and target power |
| `power_curve` | `power_curve` | read-only — power-vs-n figure (PNG) + (n, power) arrays (JSON) |
| `simulate_power` | `simulate_power` | read-only — Monte Carlo power for a no-formula design + MC CI |

The four closed-form perks wrap the bundled `power.py` interface over statsmodels/scipy
(tests: `t_ind`, `t_paired`, `t_one`, `anova`, `two_proportions`, `one_proportion`,
`correlation`, `chi2`, `linear_regression`). `simulate_power` wraps the Monte Carlo
harness for designs with no closed form (`two_group`, `logistic`, `cluster_randomized`,
`linear_mixed`). Every perk is read-only: it computes numbers and writes artifacts only
under `record_store`, mutating no external state.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `statistical-power` — MIT (see LICENSE.txt).
