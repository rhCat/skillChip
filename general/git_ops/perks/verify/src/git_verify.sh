#!/usr/bin/env bash
# git_verify — validator: assert REPO_DIR satisfies REQUIRE (git history and/or a wired remote). Read-only.
# The gate IS the exit code: 0 iff every required condition holds, else 1. Writes git_verify.json.
set -uo pipefail
: "${REPO_DIR:?}" "${RECORD_STORE:?}"
REQUIRE="${REQUIRE:-history+remote}"
OUT="${RECORD_STORE%/}/git_verify.json"

fail() {   # reason -> write a fail verdict, echo it, exit 1
  printf '{"tool":"git_verify","status":"fail","repo":"%s","require":"%s","reason":"%s"}\n' \
    "$REPO_DIR" "$REQUIRE" "$1" > "$OUT"
  cat "$OUT"; exit 1
}

cd "$REPO_DIR" 2>/dev/null || fail "REPO_DIR not accessible"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "not a git repository"

COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo 0)
REMOTES=$(git remote 2>/dev/null | grep -c . || true)
HIST_OK=$([ "${COMMITS:-0}" -ge 1 ] && echo true || echo false)
REM_OK=$([ "${REMOTES:-0}" -ge 1 ] && echo true || echo false)

SAT=true; MISSING=""
case "$REQUIRE" in *history*) [ "$HIST_OK" = true ] || { SAT=false; MISSING="${MISSING}history "; };; esac
case "$REQUIRE" in *remote*)  [ "$REM_OK"  = true ] || { SAT=false; MISSING="${MISSING}remote "; };; esac

printf '{"tool":"git_verify","status":"%s","repo":"%s","require":"%s","history":{"ok":%s,"commits":%s},"remote":{"ok":%s,"count":%s},"satisfied":%s,"missing":"%s","report":"%s"}\n' \
  "$([ "$SAT" = true ] && echo ok || echo fail)" "$REPO_DIR" "$REQUIRE" \
  "$HIST_OK" "${COMMITS:-0}" "$REM_OK" "${REMOTES:-0}" "$SAT" "${MISSING% }" "$OUT" > "$OUT"
cat "$OUT"
[ "$SAT" = true ]
