---
skill: opentrons-integration
name: Opentrons Integration (Protocol API v2)
perks: [simulate, scaffold-basic, scaffold-pcr, scaffold-serial-dilution]
---

# opentrons-integration — Opentrons Integration (Protocol API v2)

Simulate an Opentrons Protocol API v2 file (read-only) or scaffold a ready-to-edit protocol
template (basic transfer, PCR setup, serial dilution) into the record store.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report/file + the executor run-ledger.
`simulate` shells out to the `opentrons` package (`opentrons_simulate`); when that package is
absent the porter degrades gracefully (still writes its log, exits 0) instead of failing.

## Perks
| perk | tool | nature |
|---|---|---|
| `simulate` | `ot_simulate` | read-only / safe — dry-run a protocol via `opentrons_simulate` (no robot) |
| `scaffold-basic` | `ot_scaffold_basic` | read-only — emit the basic transfer protocol template |
| `scaffold-pcr` | `ot_scaffold_pcr` | read-only — emit the PCR-setup (thermocycler) protocol template |
| `scaffold-serial-dilution` | `ot_scaffold_serial_dilution` | read-only — emit the serial-dilution protocol template |

`simulate` never touches a physical robot: it runs `opentrons_simulate` against a protocol file
and captures the simulated run log to `simulate.log`. The three `scaffold-*` perks are pure
stdlib file emitters — each copies one vendored Protocol API v2 template (`.py`) into the store
so it can be edited and then simulated/run. All four perks are `destructive: false`.

## How to use it
Pick a perk (`simulate`, `scaffold-basic`, `scaffold-pcr`, or `scaffold-serial-dilution`),
copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `opentrons-integration` — MIT (see LICENSE.txt).
