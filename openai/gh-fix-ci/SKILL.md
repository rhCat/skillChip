---
skill: gh-fix-ci
name: GitHub Fix CI
perks: [inspect]
---

# gh-fix-ci — GitHub Fix CI

Inspect failing GitHub PR checks, fetch GitHub Actions logs for actionable failures, and extract a
failure snippet — read-only, so a human can review root cause before any fix is drafted.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under
`record_store`. LOGS TO CHECK: that line + `checks.json` + the executor run-ledger. The op needs the
`gh` CLI authenticated against a live GitHub repo + the GitHub Actions API; when `gh` is absent or the
repo/PR is unreachable the porter degrades to an empty report and still exits 0.

## Perks
| perk | tool | nature |
|---|---|---|
| `inspect` | `inspect_pr_checks` | read-only / safe (reads PR checks + Actions logs, writes `checks.json`) |

The `inspect` perk only reads state: it resolves the PR (current branch PR by default, or the supplied
`PR`), lists failing checks, fetches the GitHub Actions run/job logs for each, extracts a failure
snippet, and writes a JSON report. Non-GitHub-Actions checks (for example Buildkite) are labelled
external and only their URL is reported. Nothing is pushed or mutated, so it is `destructive: false`.

## How to use it
Pick the `inspect` perk, copy `ledger.json` → `task-ledger.json`, fill `REPO_DIR` (and optionally `PR`)
plus `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [openai/skills](https://github.com/openai/skills) `gh-fix-ci` — Apache-2.0 (see LICENSE.txt).
