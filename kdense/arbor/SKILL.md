---
skill: arbor
name: Arbor (Hypothesis Tree Refinement)
perks: [init, observe, add-node, set-status, set-evidence, propagate, prune, merge, cycle, status, validate]
---

# arbor — Arbor (Hypothesis Tree Refinement)

Manage the durable hypothesis-tree state for an Arbor-style Autonomous Optimization (AO) run. Each perk is one deterministic operation on the `.arbor/` state (tree + run config) under `record_store`: bookkeeping the coordinator delegates so it can spend judgment on what the evidence means.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under `record_store`. The hypothesis-tree state lives in `record_store/run/.arbor/` (`tree.json` + `run.json`); every tool also appends its captured CLI output to a named `.txt` report. LOGS TO CHECK: that JSON line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `init` | `arbor_init` | create the tree + run config for a new AO run |
| `observe` | `arbor_observe` | read-only projection of the research state (start of each cycle) |
| `add-node` | `arbor_add_node` | Ideate — add a pending child hypothesis under a parent |
| `set-status` | `arbor_set_status` | mark a node's lifecycle status (e.g. `running` before dispatch) |
| `set-evidence` | `arbor_set_evidence` | Backpropagate (leaf) — write an executor report into its node |
| `propagate` | `arbor_propagate` | Backpropagate (upward) — abstract a leaf insight to ancestors / root |
| `prune` | `arbor_prune` | Decide — prune a falsified subtree, recording why |
| `merge` | `arbor_merge` | Decide — held-out merge gate; promote M_best only if test improves |
| `cycle` | `arbor_cycle` | increment the coordinator cycle counter |
| `status` | `arbor_status` | read-only ASCII render of the tree (for reports) |
| `validate` | `arbor_validate` | read-only invariant check on the tree |

All perks are local file operations on the `.arbor/` state — none mutate a remote or live service, so every perk is `destructive: false`. The state manager (`tree.py`) is pure Python stdlib: it keeps the tree consistent and auditable but never decides which hypothesis to try or whether one is good — that judgment stays with the coordinator.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`, then validate → compose → compile → oversight → executor. Run `init` once to create the run, then loop the cycle perks (`observe` → `add-node` → `set-status` → `set-evidence` → `propagate` → `prune`/`merge` → `cycle`) against the same `record_store`.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `arbor` — MIT (see LICENSE.txt).
