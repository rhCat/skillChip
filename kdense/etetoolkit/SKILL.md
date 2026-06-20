---
skill: etetoolkit
name: ETE Toolkit (Phylogenetics)
perks: [stats, convert, reroot, prune, ascii, leaves, visualize]
---

# etetoolkit — ETE Toolkit (Phylogenetics)

Phylogenetic tree operations built on ETE (Environment for Tree Exploration): compute statistics,
convert Newick formats, reroot, prune, list leaves, render ASCII, and render publication figures —
all read-only / local file producers.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under
`record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger. The science
core (`ete3`) is heavy; when it is absent the porter degrades gracefully (still writes its report,
still exits 0) so the contract's `output_exists` holds.

## Perks
| perk | tool | nature |
|---|---|---|
| `stats` | `ete_stats` | read-only — leaf/node counts, tree depth, branch-length + support stats -> `stats.txt` |
| `convert` | `ete_convert` | read-only — Newick format conversion -> `convert.log` (+ `converted.nw` when ete3 present) |
| `reroot` | `ete_reroot` | read-only — reroot by outgroup or midpoint -> `reroot.log` (+ `rerooted.nw`) |
| `prune` | `ete_prune` | read-only — prune to taxa list -> `prune.log` (+ `pruned.nw`) |
| `ascii` | `ete_ascii` | read-only — ASCII tree art -> `ascii.txt` |
| `leaves` | `ete_leaves` | read-only — list leaf names -> `leaves.txt` |
| `visualize` | `ete_visualize` | read-only — render PNG/PDF/SVG figure -> `visualize.log` (+ image; needs Qt) |

Every perk reads an input tree and produces files under `record_store`; none mutates a remote or
live service, so all are `destructive: false`. The `visualize` perk needs a Qt rendering backend to
emit the image itself; without it the porter still records a log and exits cleanly.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars (`TREE_FILE`, the format/option
vars the perk declares) + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `etetoolkit` — MIT (see LICENSE.txt).
