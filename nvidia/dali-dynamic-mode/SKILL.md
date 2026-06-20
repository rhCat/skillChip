---
skill: dali-dynamic-mode
name: DALI Dynamic Mode
perks: [check]
---

# dali-dynamic-mode — DALI Dynamic Mode

Guide and review code that uses DALI's imperative dynamic-mode API,
`nvidia.dali.experimental.dynamic` (`ndd`). The `check` perk statically scans a Python
file for pipeline-mode leftovers and dynamic-mode anti-patterns the skill warns about.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `check` | `dali_check` | read-only / safe (static lint — never imports DALI, never runs the file) |

The `check` perk reads a single `.py` file and reports the documented mistakes —
`device="mixed"`, `@pipeline_def` / `pipe.build()` / `pipe.run()`, `fn.*` / `ndd.fn.*`
operators, lowercase reader classes (`ndd.readers.file`), `batch[i]` indexing, scattered
`.evaluate()` calls, and random ops missing `batch_size` — writing one findings JSON to
`record_store`. It is pure static analysis (stdlib `ast`/regex only): it does NOT need a
GPU, a CUDA build, or DALI installed, so it is `destructive: false`.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `dali-dynamic-mode` (Apache-2.0).
