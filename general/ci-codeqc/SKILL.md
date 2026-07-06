---
skill: ci-codeqc
name: CI code-QC generator
perks: [github_actions, gate]
---

# ci-codeqc — generate a code-QC CI and gate a repo's freshness

Two pathways for a repo's continuous quality: **generate** a code-QC GitHub Actions workflow, and **gate**
that a self-model tracks its implementation.

- **`github_actions`** — writes a GitHub Actions **code-qc** workflow (`.github/workflows/codeqc.yml`):
  checkout → setup Python → install → **ruff** (lint) → **mypy** (types) → **pytest --cov** (test).
  Idempotent — re-running regenerates it; an existing workflow is backed up to `.bk` first.
- **`gate`** — a read-only **freshness validator**: the `MODEL` files must be at least as new (by newest
  git commit) as the `SURFACE` files they track; a stale model **fails** the gate. This is the H0 rule —
  *self-blueprints must be no older than the last enforcement-surface commit* — as a runnable check.

## What to look out for
`github_actions` emits `action` = `created | updated` + the workflow path. `gate` emits `stale` +
`surface_newest`/`model_newest` (ts + file) into `gate.json`; its **exit code IS the verdict** (0 fresh,
1 stale). LOGS TO CHECK: that line + `${record_store}/codeqc.yml` or `gate.json` + the executor run-ledger.

## How to use it
- **`github_actions`** — fill `PROJECT_DIR` (+ optional `SRC_DIR`, `TEST_DIR`, `PYTHON_VERSION`, `BRANCH`);
  the workflow lands in the target repo; commit it.
- **`gate`** — fill `PROJECT_DIR` (+ optional `MODEL_GLOB` [default `*.blueprint.json`], `SURFACE_GLOB`
  [default `infra/govern`]); reporting-and-gating, writes nothing to the target repo.

Then validate → compose → compile → oversight → executor.
