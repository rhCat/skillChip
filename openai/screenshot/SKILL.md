---
skill: screenshot
name: Screenshot Capture
perks: [capture, list_windows, check_permissions]
---

# screenshot — Screenshot Capture

Capture a desktop/app/window/region screenshot to a file, list the capturable on-screen windows, or preflight macOS Screen Recording permission.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `capture` | `take_screenshot` | read-only / safe — writes one PNG file under `record_store` (full screen, app, window, or `--region`) |
| `list_windows` | `list_windows` | read-only — lists matching on-screen window ids (macOS) to a text report |
| `check_permissions` | `check_permissions` | preflight — checks (and may request) macOS Screen Recording permission; records status only |

`capture` and `list_windows` wrap the vendored `take_screenshot.py`; offline they run in `CODEX_SCREENSHOT_TEST_MODE` and degrade to a fixture PNG / fixture window list, so the contract holds with only `python3` present. `check_permissions` wraps the vendored `ensure_macos_permissions.sh`; the live check needs macOS + `swift`, so its porter degrades gracefully and records the status. None of the perks mutate user data, so all are `destructive: false`.

## How to use it
Pick a perk (`capture`, `list_windows`, or `check_permissions`), copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [openai/skills](https://github.com/openai/skills) `screenshot` — Apache-2.0 (see LICENSE.txt).
