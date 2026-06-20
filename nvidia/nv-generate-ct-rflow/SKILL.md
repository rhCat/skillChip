---
skill: nv-generate-ct-rflow
name: NV-Generate-CT (rflow-ct)
perks: [generate, list-anatomies, preflight, run-ct-mask, run-ct-from-mask, run-ct-image]
---

# nv-generate-ct-rflow — NV-Generate-CT (rflow-ct)

Generate paired synthetic CT volumes + masks with NVIDIA NV-Generate-CTMR's rectified-flow
pipeline. A thin wrapper that shells out to upstream `scripts.inference`; not for production
training data without independent review.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `generate` | `run_rflow_ct` | destructive (runs GPU diffusion inference, downloads/caches model weights, contacts network) |
| `list-anatomies` | `list_anatomies` | read-only (offline catalog lookup over `label_dict.json`; no GPU, no network) |
| `preflight` | `run_rflow_ct_preflight` | read-only (validates a config + previews cost via `--preflight-only`; never launches inference) |
| `run-ct-mask` | `run_ct_mask` | destructive (standalone GPU mask diffusion; defaults to preflight, gated behind explicit confirm) |
| `run-ct-from-mask` | `run_ct_from_mask` | destructive (GPU CT-from-mask inference; defaults to preflight, gated behind explicit confirm) |
| `run-ct-image` | `run_ct_image` | destructive (GPU CT image-only diffusion; defaults to preflight, gated behind explicit confirm) |

The `generate` wrapper runs preflight on every invocation (config-schema bounds, anatomy/body-region
validation, FOV minimums, dataset + CUDA presence, VRAM/wall-time estimate), then invokes
upstream `python -m scripts.inference --version rflow-ct`. Because it launches heavy GPU
inference and may fetch ~5.5 GB of weights, the perk is declared `destructive: true`; the
executor gates it accordingly.

`list-anatomies` and `preflight` are the offline, read-only operations: the first prints the
canonical anatomy class names (use it before authoring an `anatomy_list` /
`controllable_anatomy_size` override), the second runs the same preflight `generate` does but
stops before inference so you can validate a config and preview its cost for free. `run-ct-mask`,
`run-ct-from-mask`, and `run-ct-image` expose the three less-common upstream generation modes
(raw MAISI mask synthesis, CT image from an existing label mask, and CT image-only generation);
each defaults to a preflight validation report and only launches GPU inference when explicitly
confirmed (`PREFLIGHT=0 CONFIRM=1`).

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `nv-generate-ct-rflow` (Apache-2.0).
