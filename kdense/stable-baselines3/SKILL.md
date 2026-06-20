---
skill: stable-baselines3
name: Stable Baselines3 (RL)
perks: [train, evaluate, custom_env]
---

# stable-baselines3 — Stable Baselines3 (RL)

Train, evaluate, or validate a Gymnasium custom env for a Stable Baselines3 reinforcement-learning agent.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
Each perk runs a vendored K-Dense template script unchanged; the porter translates ledger vars into
its call. The cores need `stable-baselines3` (>=2.8, Python 3.10+), `gymnasium`, and `torch` — when those
are absent the porter degrades gracefully and still writes a non-empty report so the contract holds.

## Perks
| perk | tool | nature |
|---|---|---|
| `train` | `sb3_train` | read-only / local — trains an agent, writes model + logs under `record_store` |
| `evaluate` | `sb3_evaluate` | read-only / local — loads a saved model, runs `evaluate_policy`, reports reward stats |
| `custom_env` | `sb3_check_env` | read-only / local — instantiates a custom Gym env and runs SB3 `check_env` |

`train` wraps `train_rl_agent.py` (`make_vec_env` + `EvalCallback`/`CheckpointCallback` + `model.learn` +
`model.save`). `evaluate` wraps `evaluate_agent.py` (`PPO.load` + `evaluate_policy`). `custom_env` wraps
`custom_env_template.py` (`CustomEnv` + `check_env`). All three only write under `record_store`; none mutate
a remote or live service, so all are `destructive: false`.

## How to use it
Pick a perk (`train`, `evaluate`, or `custom_env`), copy `ledger.json` → `task-ledger.json`, fill its vars +
`record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `stable-baselines3` — MIT (see LICENSE.txt).
