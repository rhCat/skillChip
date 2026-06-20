---
skill: nv-reason-cxr
name: NV-Reason-CXR (chest X-ray reasoning)
perks: [reason]
---

# nv-reason-cxr — NV-Reason-CXR (chest X-ray reasoning)

Thin wrapper around NVIDIA NV-Reason-CXR-3B that reasons over a chest X-ray (PNG/JPEG or JSON fixture) and emits structured JSON. Output is engineering evidence only — not a diagnosis, clinical report, or triage decision.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `reason` | `run_nv_reason_cxr` | destructive (downloads multi-GB model weights, runs GPU/remote inference, contacts huggingface.co / *.hf.space) |

The `reason` perk runs the upstream wrapper. By default (`--backend local`) it downloads `nvidia/NV-Reason-CXR-3B` to the Hugging Face cache and runs Transformers inference on CUDA; with `--backend hf-space-api` it sends the image to the public Hugging Face Space; with `MOCK_NV_REASON_CXR=1` (or a fixture requesting mock) it emits a deterministic dry-run response for command-shape smoke tests. Because the live paths download weights and call remote inference, the perk is declared `destructive: true` and the executor gates it accordingly.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars (`CXR_INPUT`, optional `PROMPT`, optional `BACKEND`) + `record_store`, then validate -> compose -> compile -> oversight -> executor. The structured-JSON result is written under `record_store` as `result.json`. For a no-weights wiring check, point `CXR_INPUT` at a JSON fixture with `"mock": true` (or export `MOCK_NV_REASON_CXR=1`).

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `nv-reason-cxr` (Apache-2.0). Model weights are under the NVIDIA OneWay Noncommercial License Agreement.
