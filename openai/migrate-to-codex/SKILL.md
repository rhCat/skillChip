---
skill: migrate-to-codex
name: Migrate to Codex
perks: [scan, plan, doctor, validate, migrate]
---

# migrate-to-codex — Migrate to Codex

Inspect a Claude source tree (instructions, skills/commands, MCP config, hooks, subagents, plugins)
and migrate the supported surfaces into Codex artifacts: `AGENTS.md`, `.codex/config.toml`,
`.agents/skills/`, `.codex/agents/`, and `.codex/hooks.json`. The four inspection perks are read-only;
only `migrate` writes.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under
`record_store`. LOGS TO CHECK: that line + the named report (`scan.txt` / `plan.txt` / `doctor.txt` /
`validate.txt` / `migrate.txt`) + the executor run-ledger. The vendored migrator imports `tomllib`
and needs Python 3.11+ to do real work; on older Python the porters degrade gracefully (empty report,
exit 0) rather than crash.

## Perks
| perk | tool | nature |
|---|---|---|
| `scan` | `mtc_scan` | read-only / safe (`--scan-only`: inventory source surfaces) |
| `plan` | `mtc_plan` | read-only / safe (`--plan`: staged artifact paths + report rows, no writes) |
| `doctor` | `mtc_doctor` | read-only / safe (`--doctor`: readiness, manual-review, collision/orphan risks) |
| `validate` | `mtc_validate` | read-only / safe (`--validate-target`: check a migrated Codex target) |
| `migrate` | `mtc_migrate` | destructive — writes/overwrites generated Codex artifacts under the target (`--replace` also deletes orphans) |

The `scan`, `plan`, `doctor`, and `validate` perks never write target files. The `migrate` perk mutates
the local Codex target filesystem (creating, overwriting, and — with `MIGRATE_FLAGS=--replace` — deleting
generated artifacts), so it is declared `destructive: true` and the executor gates it accordingly. Pass
`MIGRATE_FLAGS=--dry-run` to preview a migration without writing, or `--mcp`/`--skills`/`--subagents` to
scope the surfaces.

## How to use it
Pick a perk (`scan`, `plan`, `doctor`, `validate`, or `migrate`), copy `ledger.json` → `task-ledger.json`,
fill its vars + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [openai/skills](https://github.com/openai/skills) `migrate-to-codex` — Apache-2.0 (see LICENSE.txt).
