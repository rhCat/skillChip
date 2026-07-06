---
skill: git_ops
name: Git operations
perks: [snapshot, status, verify]
---

# git_ops — Git operations

Local-repo git pathways: take a snapshot commit, read porcelain status, verify a repo's shape. **Push is
intentionally not a skill** — publishing stays a human-decided step, and history rewrites (`--force`,
`reset --hard`) are gated by the oversight rules.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under
`record_store`. LOGS TO CHECK: that line + `git_snapshot.json` / `git_status.txt` / `git_verify.json` +
the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `snapshot` | `git_snapshot` | stage all + commit (no-op when clean; never pushes) |
| `status` | `git_status` | read-only |
| `verify` | `git_verify` | read-only validator — the exit code IS the verdict |

- **`snapshot`** — set `REPO_DIR` + `MESSAGE`; commits only if the tree is dirty and records the
  commit hash. Local only — no push.
- **`status`** — set `REPO_DIR`; output `git_status.txt`. Reporting only.
- **`verify`** — set `REPO_DIR` (+ optional `REQUIRE` = `history` | `remote` | `history+remote`,
  default `history+remote`); asserts the repo has commit history and/or a wired remote. Read-only;
  exits `0` iff satisfied, `1` otherwise (the gate is the exit code). Output `git_verify.json`.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`, then
validate → compose → compile → oversight → executor.
