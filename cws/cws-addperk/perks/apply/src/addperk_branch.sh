#!/usr/bin/env bash
# addperk_branch — create + checkout the perk-update branch. Structured JSON.
set -uo pipefail
: "${SKILL:?}" "${PERK:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# the skillChip repo (where the skill lives + formulate commits) — mirrors registry.SKILLCHIP: env override,
# else the cyberware repo's skillChip. A fixed-depth ".." walk is fragile under the cws/<skill> layout and
# could silently land on a different-but-valid git repo, so resolve it structurally and guard it.
REPO="${CYBERWARE_SKILLCHIP:-}"
if [ -z "$REPO" ]; then
  D="$HERE"
  while [ "$D" != "/" ] && [ ! -d "$D/infra/govern" ]; do D="$(dirname "$D")"; done
  REPO="$D/skillChip"
fi
git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || { printf '{"tool":"addperk_branch","status":"fail","error":"skillChip git work-tree not found at %s"}\n' "$REPO"; exit 1; }
cd "$REPO" || exit 1
BR="perk/${SKILL}-${PERK}"
git checkout -b "$BR" 2>/dev/null || git checkout "$BR"
RC=$?
printf '{"tool":"addperk_branch","status":"%s","branch":"%s"}\n' "$([ $RC -eq 0 ] && echo ok || echo fail)" "$BR" | tee "${RECORD_STORE%/}/branch.json"
exit $RC
