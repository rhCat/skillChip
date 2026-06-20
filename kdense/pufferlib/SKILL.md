---
skill: pufferlib
name: PufferLib (High-Performance RL)
perks: [env_scaffold, train]
---

# pufferlib — PufferLib (High-Performance RL)

Scaffold a custom PufferEnv environment (read-only) or run a PuffeRL PPO training script (local compute). PufferLib is a high-performance reinforcement-learning framework with vectorized environments, native multi-agent support, and an optimized PPO+LSTM trainer (PuffeRL).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `env_scaffold` | `env_scaffold` | read-only / safe — materialize + self-test a single/multi-agent PufferEnv template |
| `train` | `train` | local compute — run the PuffeRL PPO training script (needs `pufferlib` + `torch`, GPU for real throughput) |

The `env_scaffold` perk materializes the PufferEnv environment template to `record_store` and, when `pufferlib` is importable, runs its built-in `test_environment()` self-check; it never touches a remote service. The `train` perk runs the PuffeRL training template (`procgen-coinrun` by default) and writes a training log; it is local compute (no remote mutation) and degrades gracefully when the heavy RL stack is absent.

## How to use it
Pick a perk (`env_scaffold` or `train`), copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `pufferlib` — MIT (see LICENSE.txt).
