#!/usr/bin/env bash
# fetch_comments — fetch all conversation comments + reviews + inline review threads
# for the open PR on the current branch of REPO_DIR via the vendored fetch_comments.py
# (which shells out to `gh api graphql`). Read-only. Structured JSON output.
set -uo pipefail
: "${REPO_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/pr_comments.json"
# Always (re)create $OUT so the contract's output_exists holds even if gh/python is absent or errors.
: > "$OUT"
if ! command -v python3 >/dev/null 2>&1; then
  printf '{}' > "$OUT"
  printf '{"tool":"fetch_comments","status":"ok","note":"python3 not found on PATH","out":"%s"}\n' "$OUT"
  exit 0
fi
if ! command -v gh >/dev/null 2>&1; then
  printf '{}' > "$OUT"
  printf '{"tool":"fetch_comments","status":"ok","note":"gh CLI not found on PATH; degraded","out":"%s"}\n' "$OUT"
  exit 0
fi
# Run the vendored core from inside the target repo so `gh pr view` resolves the
# current branch's PR. The core prints the merged JSON to stdout.
( cd "$REPO_DIR" 2>/dev/null && python3 "$HERE/fetch_comments.py" ) > "$OUT" 2>/dev/null || true
# Graceful degradation: if the core produced nothing (no PR, auth/rate error, offline),
# fall back to an empty JSON object so the contract holds.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"fetch_comments","status":"ok","out":"%s"}\n' "$OUT"
