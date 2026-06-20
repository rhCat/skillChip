---
skill: gh-address-comments
name: GitHub PR Comment Handler
perks: [fetch-comments]
---

# gh-address-comments — GitHub PR Comment Handler

Fetch all conversation comments, reviews, and inline review threads for the open
GitHub PR associated with the current branch, so they can be triaged and addressed.

## What to look out for
The tool emits one line of structured JSON (the audit + debug log) and writes its
artifact under `record_store`. LOGS TO CHECK: that line + `pr_comments.json` + the
executor run-ledger. The core shells out to `gh api graphql` / `gh pr view`, so it
needs an authenticated `gh` CLI (`gh auth login`) and a branch with an open PR; when
`gh` is absent or unauthenticated the porter degrades to an empty `{}` artifact.

## Perks
| perk | tool | nature |
|---|---|---|
| `fetch-comments` | `fetch_comments` | read-only / safe (`gh pr view` + `gh api graphql`, paginated) |

The `fetch-comments` perk only reads from GitHub: it resolves the PR for the current
branch, then pages through conversation comments, review submissions, and inline
review threads (with resolved/outdated state), writing the merged result to
`pr_comments.json`. It never mutates the PR or the repo, so it is `destructive: false`.

## How to use it
Pick the `fetch-comments` perk, copy `ledger.json` → `task-ledger.json`, fill `REPO_DIR`
+ `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [openai/skills](https://github.com/openai/skills) `gh-address-comments` — Apache-2.0 (see LICENSE.txt).
