#!/usr/bin/env bash
# ci_gate — freshness validator: the MODEL files must be at least as new (by newest git commit) as the
# SURFACE files they track. The gate IS the exit code: 0 iff the model is current, 1 if the surface
# changed AFTER it (a stale self-model, e.g. self-blueprints older than the last enforcement-surface
# commit). Read-only over git history. Writes gate.json.
set -uo pipefail
: "${PROJECT_DIR:?}" "${RECORD_STORE:?}"
MODEL_GLOB="${MODEL_GLOB:-*.blueprint.json}"
SURFACE_GLOB="${SURFACE_GLOB:-infra/govern}"
OUT="${RECORD_STORE%/}/gate.json"

fail() {   # reason -> write a fail verdict, echo it, exit 1
  printf '{"tool":"ci_gate","status":"fail","project":"%s","reason":"%s"}\n' "$PROJECT_DIR" "$1" > "$OUT"
  cat "$OUT"; exit 1
}
cd "$PROJECT_DIR" 2>/dev/null || fail "PROJECT_DIR not accessible"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "not a git repository"

newest() {   # pathspec -> "<ts>\t<file>" of the newest-committed matching tracked file (ts=0 if none)
  local mx=0 mf="" t f
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    t=$(git log -1 --format=%ct -- "$f" 2>/dev/null)
    if [ -n "$t" ] && [ "$t" -gt "$mx" ]; then mx=$t; mf=$f; fi
  done < <(git ls-files -- "$1")
  printf '%s\t%s' "$mx" "$mf"
}
IFS=$'\t' read -r S_TS S_F < <(newest "$SURFACE_GLOB")
IFS=$'\t' read -r M_TS M_F < <(newest "$MODEL_GLOB")
STALE=$([ "${S_TS:-0}" -gt "${M_TS:-0}" ] && echo true || echo false)

printf '{"tool":"ci_gate","status":"%s","project":"%s","model_glob":"%s","surface_glob":"%s","surface_newest":{"ts":%s,"file":"%s"},"model_newest":{"ts":%s,"file":"%s"},"stale":%s,"report":"%s"}\n' \
  "$([ "$STALE" = true ] && echo fail || echo ok)" "$PROJECT_DIR" "$MODEL_GLOB" "$SURFACE_GLOB" \
  "${S_TS:-0}" "$S_F" "${M_TS:-0}" "$M_F" "$STALE" "$OUT" > "$OUT"
cat "$OUT"
[ "$STALE" = false ]
