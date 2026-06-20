---
skill: skill-installer
name: Skill Installer
perks: [list, install]
---

# skill-installer — Skill Installer

List installable Codex skills from a GitHub repo (read-only) or install a skill into `$CODEX_HOME/skills` (destructive).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
Both perks reach the network (GitHub API / codeload). The porters degrade gracefully when the
network or `python3` core is unavailable: the output file is always created, so the contract holds.

## Perks
| perk | tool | nature |
|---|---|---|
| `list` | `list_skills` | read-only / safe (GitHub contents API → skills list as JSON) |
| `install` | `install_skill` | destructive (downloads a skill and writes it into `$CODEX_HOME/skills`) |

The `list` perk only reads a repo's directory listing via the GitHub contents API and writes the
skill names to `skills.json`. The `install` perk fetches a skill (zip download, with git sparse-checkout
fallback) and copies it into the destination skills dir; because it writes a new skill tree onto the
local filesystem it is declared `destructive: true` and the executor gates it accordingly.

## How to use it
Pick a perk (`list` or `install`), copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [openai/skills](https://github.com/openai/skills) `skill-installer` — Apache-2.0 (see LICENSE.txt).
