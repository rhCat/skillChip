---
skill: labarchive-integration
name: LabArchives Integration (ELN API)
perks: [setup-config, list-notebooks, backup-notebook, create-entry, upload-attachment, create-comment]
---

# labarchive-integration — LabArchives Integration (ELN API)

Programmatic access to the LabArchives electronic-lab-notebook REST API: configure credentials, list and back up notebooks (read-only), and create entries, comments, and attachments (destructive — they mutate the live ELN).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger. All remote perks need the `labarchives-py` package and live API credentials/network; when the package is absent each tool degrades gracefully (writes `{}` and exits 0) so the contract still holds offline.

## Perks
| perk | tool | nature |
|---|---|---|
| `setup-config` | `setup_config` | read-only / local — writes `config.yaml` from env vars (no network) |
| `list-notebooks` | `list_notebooks` | read-only remote — lists accessible notebooks |
| `backup-notebook` | `backup_notebook` | read-only remote — downloads a notebook backup to a file |
| `create-entry` | `create_entry` | destructive — creates a notebook entry on the live ELN |
| `upload-attachment` | `upload_attachment` | destructive — uploads a file attachment to an entry |
| `create-comment` | `create_comment` | destructive — adds a comment to an entry |

`setup-config` only writes a local `config.yaml`; it never touches the network. `list-notebooks` and `backup-notebook` are read-only against the remote service. `create-entry`, `upload-attachment`, and `create-comment` all mutate the live notebook and are therefore declared `destructive: true`; the executor gates them accordingly.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `labarchive-integration` — MIT (see LICENSE.txt).
