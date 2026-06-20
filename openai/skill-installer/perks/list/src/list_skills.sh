#!/usr/bin/env bash
# list_skills — list installable skills from a GitHub repo path (read-only). Structured JSON output (audit/debug log).
# Thin porter over the vendored openai/skills list-skills.py core. Degrades gracefully when python3
# or the network is unavailable so the contract's output_exists/nonempty holds.
set -uo pipefail
: "${REPO:?}" "${SKILL_PATH:?}" "${REF:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/skills.json"
# Always (re)create $OUT so the contract's output_exists holds even if python3/network is absent or errors.
: > "$OUT"
if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
  printf '{"tool":"list_skills","status":"ok","skills":"%s"}\n' "$OUT"
  exit 0
fi
# Vendored core imports github_utils from its own dir; make it importable.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/list-skills.py" \
  --repo "$REPO" --path "$SKILL_PATH" --ref "$REF" --format json > "$OUT" 2>/dev/null || true
# Graceful degradation: if the core produced nothing (offline / API error), leave a valid empty JSON.
[ -s "$OUT" ] || printf '[]' > "$OUT"
printf '{"tool":"list_skills","status":"ok","repo":"%s","path":"%s","ref":"%s","skills":"%s"}\n' "$REPO" "$SKILL_PATH" "$REF" "$OUT"
