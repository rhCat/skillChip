---
skill: deepstream-import-vision-model
name: DeepStream Import Vision Model
perks: [import, inspect-onnx, ngc-list-files, static-batch-onnx, benchmark-charts, cleanup-staging]
---

# deepstream-import-vision-model — DeepStream Import Vision Model

Bring any object-detection vision model from HuggingFace or NVIDIA NGC into an NVIDIA DeepStream pipeline end-to-end: acquire ONNX (or export from SafeTensors), build a dynamic TensorRT engine, generate a custom nvinfer bbox parser + config, run single/multi-stream benchmarks, and emit a PDF report.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `import` | `hf_list_files` (entry) → `safetensors_to_onnx` → `inspect_onnx` → `benchmark_trtexec` → `ds_single_stream` → `benchmark_ds` → `generate_benchmark_charts` → `md_to_html_pdf` | destructive (downloads models, builds TRT engines, runs DeepStream benchmarks on GPU) |
| `inspect-onnx` | `inspect_onnx` | read-only — report an ONNX model's inputs/outputs/opset/operators/validity + machine-parseable H/W summary |
| `ngc-list-files` | `ngc_list_files` | read-only — list the files in a public NVIDIA NGC model version (NGC counterpart of `hf_list_files`) |
| `static-batch-onnx` | `static_batch_onnx` | transform — bake a fixed batch dim into a batch-1 ONNX (patch input/output dims + Reshape nodes) |
| `benchmark-charts` | `benchmark_charts` | render — produce the 5 fixed benchmark PNG charts from a `benchmark_data.json` |
| `cleanup-staging` | `cleanup_staging` | destructive — remove a model's scoped staging dirs after export (preserves the shared venv; supports dry-run) |

The `import` perk runs the documented model→engine→pipeline→report pipeline. It is `destructive: true`: it pulls model weights, creates a Python venv, builds TensorRT engines, and runs DeepStream benchmarks against the GPU. Object detection models only — classification/segmentation architectures are rejected before any build.

The remaining perks expose the skill's individual deterministic operations on their own: `inspect-onnx` (model introspection), `ngc-list-files` (NGC acquire-phase listing), `static-batch-onnx` (engine-build prep), `benchmark-charts` (report chart rendering), and `cleanup-staging` (post-export housekeeping). Each writes a structured audit manifest under `record_store` and degrades gracefully when its optional dependency (`onnx`, `matplotlib`, network) is unavailable.

## How to use it
Copy `ledger.json` → `task-ledger.json`, set the vars + record_store, then validate → compose → compile → oversight → executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `deepstream-import-vision-model` (CC-BY-4.0 AND Apache-2.0).
