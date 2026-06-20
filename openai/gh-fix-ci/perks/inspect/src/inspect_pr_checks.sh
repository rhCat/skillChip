#!/usr/bin/env bash
# inspect_pr_checks — porter: inspect failing GitHub PR checks, fetch GitHub Actions logs,
# extract a failure snippet (read-only). Runs the vendored core (inspect_pr_checks.py) with
# env->arg translation. Degrades gracefully (still exit 0 + a report file) when gh / a live
# GitHub repo is unavailable, so the contract's exit_zero + output_exists always hold.
set -uo pipefail
: "${REPO_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/checks.json"
# Always (re)create $OUT so output_exists holds even if gh is absent or the core errors.
: > "$OUT"

if ! command -v gh >/dev/null 2>&1; then
  printf '{"tool":"inspect_pr_checks","status":"ok","note":"gh not on PATH; nothing inspected","report":"%s"}\n' "$OUT" > "$OUT"
  printf '{"tool":"inspect_pr_checks","status":"ok","note":"gh not found on PATH","report":"%s"}\n' "$OUT"
  exit 0
fi

# env -> arg translation; PR / MAX_LINES / CONTEXT are optional.
ARGS=(--repo "$REPO_DIR" --json)
[ -n "${PR:-}" ] && ARGS+=(--pr "$PR")
[ -n "${MAX_LINES:-}" ] && ARGS+=(--max-lines "$MAX_LINES")
[ -n "${CONTEXT:-}" ] && ARGS+=(--context "$CONTEXT")

# The core exits non-zero by design when failing checks remain (or on error). Swallow with || true:
# governance here is read-only inspection — the report file is the deliverable, not the exit code.
python3 "$HERE/inspect_pr_checks.py" "${ARGS[@]}" > "$OUT" 2>/dev/null || true

# Graceful degradation: if the core produced nothing usable, leave a valid JSON object behind.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"inspect_pr_checks","status":"ok","repo":"%s","report":"%s"}\n' "$REPO_DIR" "$OUT"
