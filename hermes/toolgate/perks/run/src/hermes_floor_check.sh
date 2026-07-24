#!/usr/bin/env bash
# hermes_floor_check — SELF-TEST of the destructive floor, run as STEP 1 of every exec.
# Sources the pure predicate (hermes_floor.sh) and classifies every line of the pinned
# case table (floor_cases.txt). It EXECUTES NONE of the case commands — the predicate
# file contains no execution path, so a floor test can never become an incident.
# A floor that misclassifies ANY pinned case refuses the run — fail closed, BEFORE
# hermes_exec ever sees the agent's CMD.
# Output: $RECORD_STORE/floor_report.json + a JSON status line.
set -euo pipefail
: "${RECORD_STORE:?}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hermes_floor.sh
source "$HERE/hermes_floor.sh"
CASES="$HERE/floor_cases.txt"
REPORT="${RECORD_STORE%/}/floor_report.json"

jesc() { local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; printf '%s' "$s"; }

total=0; fails=0; rows=()
while IFS=$'\t' read -r want cmd || [[ -n "${want:-}" ]]; do
  [[ -z "$want" || "$want" == "#"* ]] && continue
  total=$((total + 1))
  verdict="$(floor_verdict "$cmd")" || true
  got="${verdict%%:*}"
  ok=true
  [[ "$got" == "$want" ]] || { ok=false; fails=$((fails + 1)); }
  rows+=("$(printf '{"cmd": "%s", "want": "%s", "got": "%s", "ok": %s}' \
            "$(jesc "$cmd")" "$want" "$got" "$ok")")
done <"$CASES"

# an empty/missing table is itself a floor failure — the proof must exist to pass
[[ "$total" -gt 0 ]] || fails=$((fails + 1))

{
  printf '{\n  "tool": "hermes_floor_check",\n  "total": %d,\n  "fails": %d,\n  "cases": [\n' "$total" "$fails"
  for i in "${!rows[@]}"; do
    sep=","; [[ "$i" -eq $(( ${#rows[@]} - 1 )) ]] && sep=""
    printf '    %s%s\n' "${rows[$i]}" "$sep"
  done
  printf '  ]\n}\n'
} >"$REPORT"

if [[ "$fails" -gt 0 ]]; then
  printf '{"tool":"hermes_floor_check","status":"refused","fails":%d,"total":%d,"report":"%s"}\n' \
    "$fails" "$total" "$REPORT"
  exit 3
fi
printf '{"tool":"hermes_floor_check","status":"ok","fails":0,"total":%d,"report":"%s"}\n' "$total" "$REPORT"
