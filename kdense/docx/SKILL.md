---
skill: docx
name: DOCX (Word documents)
perks: [extract, unpack, validate, comment, pack, accept-changes]
---

# docx — DOCX (Word documents)

Read, unpack, validate, comment on, repack, and accept tracked changes in Word `.docx` files. A `.docx` is a ZIP of XML parts; these perks wrap pandoc and the K-Dense Office tooling so each operation has a clear inputs->outputs contract.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger. The unpack/validate/comment/pack tools import `defusedxml`; when it is absent they degrade gracefully (the porter still writes a non-empty report and exits 0). `accept-changes` requires LibreOffice (`soffice`) on PATH.

## Perks
| perk | tool | nature |
|---|---|---|
| `extract` | `docx_extract` | read-only — `pandoc --track-changes=all` to text/markdown |
| `unpack` | `docx_unpack` | read-only — ZIP extract + pretty-print XML into a dir (no source mutation) |
| `validate` | `docx_validate` | read-only — XSD + redlining validation, auto-repair on a temp copy |
| `comment` | `docx_comment` | local — appends comment parts inside an already-unpacked dir |
| `pack` | `docx_pack` | local — writes a new `.docx` from an unpacked dir (validate + condense) |
| `accept-changes` | `docx_accept_changes` | local — LibreOffice accepts all tracked changes into a clean copy |

All perks are `destructive: false`: each either reads input or produces a new file/dir under `record_store` (or, for `comment`, edits a working copy the caller already unpacked) — none mutates a remote or live service.

## How to use it
Pick a perk, copy `ledger.json` -> `task-ledger.json`, fill its vars + `record_store`,
then validate -> compose -> compile -> oversight -> executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `docx` — MIT (see LICENSE.txt).
