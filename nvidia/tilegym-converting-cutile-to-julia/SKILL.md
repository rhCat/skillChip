---
skill: tilegym-converting-cutile-to-julia
name: cuTile Python to cuTile.jl (Julia) Conversion
perks: [check]
---

# tilegym-converting-cutile-to-julia — cuTile Python to cuTile.jl (Julia) Conversion

Convert `@ct.kernel` cuTile Python GPU kernels to Julia cuTile.jl, then statically check the
converted `.jl` file for the most common Python-to-Julia translation anti-patterns (0-indexing,
broadcasting, type names, launch API, `ct.full`/`ct.mma`/`ct.matmul`, etc.).

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `check` | `validate_cutile_jl` | read-only / safe (static analysis of a `.jl` file; no GPU, no Julia run) |

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars (`JL_FILE`) + `record_store`, then
validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `tilegym-converting-cutile-to-julia` (Apache-2.0).
