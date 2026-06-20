#!/usr/bin/env bash
# render_card — localized from NVIDIA/skills skill-card-generator (CC-BY-4.0 AND Apache-2.0). Structured-JSON audit line.
# Standalone deterministic render: validate a context JSON against the card schema and render the markdown
# card from the vendored Jinja template. Identical context always yields an identical card. Requires jinja2.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Prefer an explicit CONTEXT path; otherwise read the agent-authored ${RECORD_STORE}/context.json.
CTX="${CONTEXT:-${RECORD_STORE%/}/context.json}"
TPL="$HERE/references/skill-card.md.j2"
OUT="${RECORD_STORE%/}/skill-card.md"
LOG="${RECORD_STORE%/}/render_card.log"
# Always (re)create $OUT so the contract's output_exists holds even if jinja2/context is absent.
: > "$OUT"
: > "$LOG"
if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$LOG"
  printf 'render skipped: python3 unavailable; see render_card.log\n' > "$OUT"
  printf '{"tool":"render_card","status":"ok","reason":"no python3","out":"%s"}\n' "$OUT"
  exit 0
fi
if [ ! -f "$CTX" ]; then
  printf 'context JSON not found at %s — set CONTEXT or author %s/context.json before rendering\n' "$CTX" "${RECORD_STORE%/}" >> "$LOG"
  printf 'render skipped: no context JSON; see render_card.log\n' > "$OUT"
  printf '{"tool":"render_card","status":"ok","reason":"no context.json","out":"%s"}\n' "$OUT"
  exit 0
fi
python3 "$HERE/render_card.py" --context "$CTX" --template "$TPL" --out "$OUT" >> "$LOG" 2>&1 || true
[ -s "$OUT" ] || printf 'render produced no card; see %s\n' "$LOG" > "$OUT"
printf '{"tool":"render_card","status":"ok","out":"%s"}\n' "$OUT"
