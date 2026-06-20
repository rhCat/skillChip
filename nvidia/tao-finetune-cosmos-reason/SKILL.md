---
skill: tao-finetune-cosmos-reason
name: TAO Finetune Cosmos-Reason
perks: [finetune]
---

# tao-finetune-cosmos-reason — TAO Finetune Cosmos-Reason

Supervised fine-tuning (SFT) of **nvidia/Cosmos-Reason2-8B** on video reasoning / video-QA tasks
using FSDP-based parallelism (`dp_shard_size` per-node GPUs, `dp_replicate_size` node count), with a
DEFT gap-analysis loop over the evaluation `results.json`.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `finetune` | `analyze_gaps` | destructive (trains/finetunes an 8B model via FSDP; gated model needs `HF_TOKEN` + docker + GPU) |

The `finetune` perk drives the SFT workflow for Cosmos-Reason2-8B and its DEFT feedback loop:
`scripts/analyze_gaps.py` reads cosmos-rl evaluation `results.json`, compares each prediction's
`response` to its `gt` by exact match after `.lower().strip()`, resolves each failure's media path
from the KPI annotations, and writes a parquet of FP/FN cases. Because the skill trains/finetunes a
gated 8B model on GPU, it is declared `destructive: true`; the executor gates it accordingly.

## How to use it
Copy `ledger.json` → `task-ledger.json`, set the vars + record_store, then validate → compose →
compile → oversight → executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `tao-finetune-cosmos-reason` (Apache-2.0).
