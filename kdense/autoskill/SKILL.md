---
skill: autoskill
name: Autoskill (workflow-to-skill miner)
perks: [doctor, fetch, redact, cluster, match, synthesize, promote]
---

# autoskill — Autoskill (workflow-to-skill miner)

Mine the user's own local [screenpipe](https://github.com/screenpipe/screenpipe) workflow history into
proposed scientific skills. The pipeline fetches a time window from the local screenpipe daemon, redacts
PII, clusters repeated workflows, matches each cluster against the sibling skill library, asks an LLM to
classify reuse/compose/novel, and stages drafts the user can review and promote. Each operation is a
governed perk with explicit inputs and outputs.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under
`record_store`. LOGS TO CHECK: that line + the named output file + the executor run-ledger. Detection runs
locally; only redacted cluster summaries reach the LLM. The `fetch`, `match`, and `synthesize` perks reach
out (screenpipe loopback / heavy embedding model / LLM backend); their porters degrade gracefully and still
write a well-formed output when the dependency is absent offline.

## Perks
| perk | tool | nature |
|---|---|---|
| `doctor` | `doctor` | read-only preflight (config / skills_dir / screenpipe / llm) |
| `fetch` | `fetch_window` | read-only — paginates screenpipe `/search` (localhost) into a timeline JSON |
| `redact` | `redact` | read-only / pure — scrubs emails, keys, bearer tokens, JWTs, phones, SSNs |
| `cluster` | `cluster` | read-only / pure — segment sessions on idle gaps + cluster by app-signature |
| `match` | `match_skills` | read-only — top-k cosine match of clusters vs sibling SKILL.md descriptions |
| `synthesize` | `synthesize` | read-only — LLM judge: reuse / compose / novel + drafts a SKILL.md body |
| `promote` | `promote` | local file move — stages an approved proposal into `skills/<name>/` |

`redact` and `cluster` are pure stdlib transforms (fully hermetic). `fetch` talks to the local screenpipe
daemon, `match` loads `sentence-transformers`, and `synthesize` calls the configured LLM backend — each
declared `destructive: false` (read-only / local) and each porter writes a valid output even when its
dependency is unavailable. `promote` only moves a local directory; it refuses to overwrite an existing skill.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `autoskill` — MIT (see LICENSE.txt).
