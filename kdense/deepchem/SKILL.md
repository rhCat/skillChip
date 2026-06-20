---
skill: deepchem
name: DeepChem (Molecular ML)
perks: [predict_solubility, train_gnn, transfer_learning]
---

# deepchem — DeepChem (Molecular ML)

Featurize, split, train, evaluate, and predict molecular properties with DeepChem — scikit-learn-wrapped regressors, graph neural networks, and pretrained transfer-learning models, on MoleculeNet benchmarks or custom SMILES CSVs.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts
under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
DeepChem loads its DL backend (torch/tensorflow/jax) and RDKit lazily; the porters degrade
gracefully (still write the named report) when those heavy libraries are absent.

## Perks
| perk | tool | nature |
|---|---|---|
| `predict_solubility` | `predict_solubility` | read-only / local — train a MultitaskRegressor (Delaney ECFP or custom CSV), evaluate, predict new SMILES |
| `train_gnn` | `train_gnn` | read-only / local — train a graph neural network (gcn/gat/attentivefp/mpnn/dmpnn) on MoleculeNet or custom CSV |
| `transfer_learning` | `transfer_learning` | read-only / local — fine-tune a pretrained model (chemberta/grover/molformer) on a property task |

All three perks read inputs and write a report to `record_store`; none mutate a remote or live
service, so each is `destructive: false`. They require deepchem plus a matching DL backend
(torch/tensorflow) and RDKit at run time; without those the porter still writes its report and
exits cleanly so the contract's `output_exists` holds.

## How to use it
Pick a perk (`predict_solubility`, `train_gnn`, or `transfer_learning`), copy `ledger.json` →
`task-ledger.json`, fill its vars + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `deepchem` — MIT (see LICENSE.txt).
