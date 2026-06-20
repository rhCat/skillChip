---
skill: pytorch-lightning
name: PyTorch Lightning
perks: [scaffold_module, scaffold_datamodule, trainer_setup]
---

# pytorch-lightning — PyTorch Lightning

Scaffold LightningModule/DataModule boilerplate and emit ready-to-use Trainer configurations (read-only, file-producing).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

Every perk vendors a K-Dense template Python core. The cores `import lightning as L` / `import torch`
at module top, so a real run requires those libraries to be installed (`uv pip install lightning`).
When the libraries are absent the porter degrades gracefully: it backfills the output file with the
template source so the contract's `output_exists` / `nonempty` checks still hold.

## Perks
| perk | tool | nature |
|---|---|---|
| `scaffold_module` | `scaffold_module` | read-only / safe — writes a LightningModule boilerplate `.py` under `record_store` |
| `scaffold_datamodule` | `scaffold_datamodule` | read-only / safe — writes a LightningDataModule boilerplate `.py` under `record_store` |
| `trainer_setup` | `trainer_setup` | read-only / safe — writes Trainer configuration examples `.py` under `record_store` |

The `scaffold_module` perk emits a complete `L.LightningModule` (training/validation/test/predict steps
plus `configure_optimizers`). `scaffold_datamodule` emits a complete `L.LightningDataModule`
(`prepare_data`/`setup` plus train/val/test/predict dataloaders). `trainer_setup` emits ten common
`L.Trainer` configurations (basic, debug, production single-GPU, DDP, FSDP, DeepSpeed, hyperparameter
tuning, overfit test, time-limited, reproducible). All three are local file producers and declared
`destructive: false`.

## How to use it
Pick a perk (`scaffold_module`, `scaffold_datamodule`, or `trainer_setup`), copy `ledger.json` → `task-ledger.json`,
fill its vars + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `pytorch-lightning` — MIT (see LICENSE.txt).
