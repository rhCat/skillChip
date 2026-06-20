#!/usr/bin/env bash
# render_card — localized from NVIDIA/skills skill-card-generator (CC-BY-4.0 AND Apache-2.0). Structured-JSON audit line.
# Step 2 of the generate sequence: render the deterministic card from an agent-authored context JSON.
# Requires jinja2 and a context JSON the agent writes to ${RECORD_STORE}/context.json after reviewing discovery.txt.
set -uo pipefail
: "${SKILL_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CTX="${RECORD_STORE%/}/context.json"
TPL="$HERE/references/skill-card.md.j2"
OUT="${RECORD_STORE%/}/skill-card.md"
LOG="${RECORD_STORE%/}/render_card.log"
: > "$LOG"
if [ ! -f "$CTX" ]; then
  printf 'context.json not found at %s — author it from discovery.txt before rendering\n' "$CTX" >> "$LOG"
  printf '{"tool":"render_card","status":"skipped","reason":"no context.json","out":"%s"}\n' "$OUT"
  exit 0
fi
python3 "$HERE/render_card.py" --context "$CTX" --template "$TPL" --out "$OUT" >> "$LOG" 2>&1 || true
[ -f "$OUT" ] || printf 'render produced no card; see %s\n' "$LOG" > "$OUT"
printf '{"tool":"render_card","status":"ok","out":"%s"}\n' "$OUT"
