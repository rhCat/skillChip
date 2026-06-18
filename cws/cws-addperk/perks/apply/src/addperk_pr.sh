#!/usr/bin/env bash
# addperk_pr — push the perk-update branch + open a PR to the working branch + notify. Structured JSON.
set -uo pipefail
: "${SKILL:?}" "${PERK:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# the skillChip repo (where the skill lives + formulate commits) — mirrors registry.SKILLCHIP: env override,
# else the cyberware repo's skillChip. A fixed-depth ".." walk is fragile under the cws/<skill> layout and
# could silently push/PR against a different-but-valid git repo, so resolve it structurally and guard it.
REPO="${CYBERWARE_SKILLCHIP:-}"
if [ -z "$REPO" ]; then
  D="$HERE"
  while [ "$D" != "/" ] && [ ! -d "$D/infra/govern" ]; do D="$(dirname "$D")"; done
  REPO="$D/skillChip"
fi
git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || { printf '{"tool":"addperk_pr","status":"fail","error":"skillChip git work-tree not found at %s"}\n' "$REPO"; exit 1; }
cd "$REPO" || exit 1
BR="perk/${SKILL}-${PERK}"
BASE="${BASE:-main}"
OUT="${RECORD_STORE%/}/pr.json"
git push -u origin "$BR" >/dev/null 2>&1 || true
PR=$(gh pr create --base "$BASE" --head "$BR" --title "perk: add ${SKILL}/${PERK}" \
      --body "Adds perk \`${PERK}\` to \`${SKILL}\` (formulated + composes). Review and merge through the agent." 2>/dev/null || echo "")
printf '{"tool":"addperk_pr","status":"ok","branch":"%s","base":"%s","pr":"%s","notify":"Perk PR opened on %s. Review it; tell the agent to merge (gh pr merge) once approved."}\n' "$BR" "$BASE" "$PR" "$BR" | tee "$OUT"
