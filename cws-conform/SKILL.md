---
skill: cws-conform
name: CWP Conformance
perks: [repin, doclint, vectors, crosslang, digestlint]
---

# cws-conform — CWP Conformance (SV-1)

Make "cyberware is a specification, not a codebase" a checkable claim. A chip's identity *is* the
canonical hash of its parts. The `repin` perk first **observes drift against the committed pins** — it
verifies each skill's files against its existing `index.json` (a reference the run did *not* produce), so
a file changed since the last pin is named — then regenerates every per-skill `index.json` (sha256 of
every file + a roll-up `skill_sha`) and the chip manifest (`index.json` with the roll-up `chip_sha`), and
records the old -> new `chip_sha` transition. The SV-1 self-referential act, performed and evidenced.

## What to look out for
`repin.json` carries `{skills, new_skills, old_chip_sha, new_chip_sha, changed, pre_drift[], drift_count,
status}`. The falsifiable signal is `pre_drift`: skills whose committed index no longer matched their
files. `status: "green"` (exit 0) means the committed chip was **already canonical** — a no-op re-pin, the
healthy steady state. `status: "drift"` (nonzero exit) means the committed pins were **stale** and the
named skills had to be rewritten — the chip is still left re-pinned, but the drift is flagged (this is the
SV-1 gate: someone changed a file without re-pinning). LOGS TO CHECK: that line + `repin.json` + the
executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `repin` | `cws_repin` | observe drift vs committed pins, regenerate indexes + manifest, record the chip_sha transition — writes to `TARGET_CHIP`'s index files |
| `doclint` | `cws_doclint` | structural conformance lint for a spec doc — exists, title, normative, on-topic (P0-V10) — read-only / safe |
| `vectors` | `cws_vectors` | replay the golden vector corpus (canonical + digest + sig verdicts) → conformance verdict (P0-T07/T17) — read-only / safe |
| `crosslang` | `cws_crosslang` | diff the independent Go verifier vs canonical.py+sign.py over the corpus — the external anchor (P0-T08) — needs the go toolchain |
| `digestlint` | `cws_digestlint` | prove every JSON-object hash routes through `cwp.canonical`, not ad-hoc `json.dumps` — the digest-cutover gate (P0-T04 / F1 / P0-V03) — read-only / safe |

- **`repin`** — set `TARGET_CHIP` (a chip dir: skill dirs each with a `perks.json`). Output: `repin.json`.
- **`digestlint`** — set `SCAN_ROOT` (a dir) + optional `EXCLUDE` (default `infra/cwp`) / `WHITELIST`
  (`relpath:line` exemptions). Output: `digestlint.json`. AST same-expression lint: no `json.dumps` may
  feed a hash outside `infra/cwp`. This is what redeems the P0-T04 digest cutover.
- **`doclint`** — set `SPEC` (a `.md`) + optional `MIN_NORMATIVE` / `REQUIRE`. Output: `doclint.json`. This
  is what redeems the P0 spec tranche (`spec/keys.md`, `privacy.md`, `time.md`, `inflight.md`, …).

## Scope (buildable now vs the full SV-1 surface)
`repin` is the canonical re-pin under the current sha256 scheme; `doclint` is the structural spec lint
(plan P0-V10) — both compose tooling that exists today (`infra/tool/skill_index`; a Markdown parse). The
remaining cws-conform perks need infra still to be built: `vectors` (replay the >=250 golden-vector corpus
through `infra/cwp`) and `crosslang` (diff the verdict stream against the independent Go verifier, the
V-EXT external anchor) land with `spec/vectors/`, `infra/cwp/`, and the Go verifier (plan P0).

## How to use it
Pick `repin`, copy `ledger.json` → `task-ledger.json`, set `TARGET_CHIP` + `record_store`, then validate
→ compose → compile → oversight → executor.
