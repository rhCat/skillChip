---
skill: harden-pyenv
name: Harden Python Env
perks: [verify]
---

# harden-pyenv — reproducible compute environment (P0-T14)

Make "the environment we run on is pinned and reproducible" a checkable claim. The compute environment is
declared once (`infra/pyenv/requirements.in`) and compiled to a hash-pinned lock
(`infra/pyenv/requirements.lock`, via `uv pip compile --generate-hashes`), mirrored as `deps.lock.json`,
SBOM'd as CycloneDX (`sbom.cdx.json`), vendored offline (`vendor/wheelhouse/` + `SHA256SUMS`), and frozen
into a checksum-pinned base image (`infra/pyenv/Dockerfile.compute` → ghcr) that CI runs on. This skill is
the gate that proves all of that holds.

## What to look out for
`harden.json` carries `{status, unpinned_imports, lock_hash_pinned, deps_lock_matches, sbom_emitted,
wheelhouse_pinned, dockerfile_pinned, osv, problems}`. The falsifiable signals: `unpinned_imports` must be
0, `sbom_emitted` true, `deps_lock_matches` true (a stale deps.lock.json = drift), and the Dockerfile
base + every fetched toolchain SHA256-pinned. `status: "ok"` (exit 0) means hardened.

## Perks
| perk | tool | nature |
|---|---|---|
| `verify` | `harden_verify` | pinned+hashed deps, deps.lock matches, CycloneDX SBOM, wheelhouse manifest, tag/checksum-pinned Dockerfile, osv clean/waivered (P0-T14) — read-only / safe |

- **`verify`** — set `LOCK` (+ optional `DEPS_LOCK`, `SBOM`, `WHEELHOUSE`, `DOCKERFILE`). Output: `harden.json`.

## How to use it
Pick `verify`, copy `ledger.json` → `task-ledger.json`, point the vars at `infra/pyenv/` + `vendor/wheelhouse`
+ the compute Dockerfile, then validate → compose → compile → oversight → executor.
