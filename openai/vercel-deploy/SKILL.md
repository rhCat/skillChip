---
skill: vercel-deploy
name: Vercel Deploy
perks: [detect-framework, deploy]
---

# vercel-deploy — Vercel Deploy

Deploy any project to Vercel. Detect a project's web framework from its `package.json` (read-only),
or package the project and deploy it to Vercel through the claimable deploy endpoint (destructive).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under
`record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger. The `deploy`
perk requires outbound network and pushes to a live Vercel endpoint — it is `destructive: true`.

## Perks
| perk | tool | nature |
|---|---|---|
| `detect-framework` | `detect_framework` | read-only / safe (inspects `package.json`, writes `framework.json`) |
| `deploy` | `vercel_deploy` | destructive (tars the project, POSTs to the Vercel claimable endpoint) — gated by `destructive: true` |

The `detect-framework` perk only reads a project's `package.json` and resolves the matching Vercel
framework slug, writing it to `framework.json` — it never packages or uploads anything. The `deploy`
perk stages + tars the project, POSTs the tarball to `codex-deploy-skills.vercel.sh`, polls the
preview URL, and returns JSON with `previewUrl` and `claimUrl`; it mutates a live service and needs
network, so it is declared `destructive: true` and the executor gates it accordingly.

## How to use it
Pick a perk (`detect-framework` or `deploy`), copy `ledger.json` → `task-ledger.json`, fill its vars +
`record_store`, then validate → compose → compile → oversight → executor.

> Localized from [openai/skills](https://github.com/openai/skills) `vercel-deploy` — MIT (see LICENSE.txt).
