---
skill: playwright
name: Playwright (Browser CLI)
perks: [open, snapshot, screenshot, pdf, extract, console, network, trace]
---

# playwright — Playwright (Browser CLI)

Drive a real browser from the terminal via `playwright-cli` (run through the bundled `npx` wrapper).
Each perk is one standalone browser operation: load a page, snapshot it, capture an artifact, extract
data, or inspect the page's console/network. CLI-first automation — not `@playwright/test` specs.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifact under
`record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger. Every porter
pre-creates its output and degrades gracefully: if `npx`/`playwright-cli`/a live browser are not
reachable, it records that fact and still emits valid output so the contract holds.

## Perks
| perk | tool | nature |
|---|---|---|
| `open` | `pw_open` | read-only / safe — navigate a session to a URL |
| `snapshot` | `pw_snapshot` | read-only — capture element-ref snapshot of the page |
| `screenshot` | `pw_screenshot` | read-only — render page (or ref) to a screenshot file |
| `pdf` | `pw_pdf` | read-only — render page to a PDF file |
| `extract` | `pw_extract` | read-only — `eval` a JS expression to extract data |
| `console` | `pw_console` | read-only — dump console messages (optional level filter) |
| `network` | `pw_network` | read-only — dump network activity |
| `trace` | `pw_trace` | read-only — `tracing-start` then `tracing-stop` around a flow |

Interaction primitives (`click`, `type`, `fill`, `press`, `select`, tab management) are pipeline
sub-steps that only run chained inside a flow — they are not standalone perks. Capture a `snapshot`
to get fresh element refs, then drive interactions inside whichever flow needs them.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [openai/skills](https://github.com/openai/skills) `playwright` — Apache-2.0 (see LICENSE.txt).
