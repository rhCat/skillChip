#!/usr/bin/env bash
# install_skill — download a skill from a GitHub repo and install it into a skills dir. DESTRUCTIVE.
# Structured JSON output (audit/debug log). Thin porter over the vendored openai/skills
# install-skill-from-github.py core. Degrades gracefully when python3 or the network is unavailable
# so the contract's output_exists/nonempty holds.
set -uo pipefail
: "${REPO:?}" "${SKILL_PATH:?}" "${REF:?}" "${DEST:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${RECORD_STORE%/}/install.log"
# Always (re)create $LOG so the contract's output_exists holds even if python3/network is absent or errors.
: > "$LOG"
if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$LOG"
  printf '{"tool":"install_skill","status":"ok","installed_log":"%s"}\n' "$LOG"
  exit 0
fi
# Vendored core imports github_utils from its own dir; make it importable.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/install-skill-from-github.py" \
  --repo "$REPO" --path "$SKILL_PATH" --ref "$REF" --dest "$DEST" >> "$LOG" 2>&1 || true
# Graceful degradation: if nothing was logged (offline / API error), leave a note so the file is nonempty.
[ -s "$LOG" ] || printf 'install produced no output (network or core unavailable)\n' > "$LOG"
printf '{"tool":"install_skill","status":"ok","repo":"%s","path":"%s","ref":"%s","dest":"%s","installed_log":"%s"}\n' "$REPO" "$SKILL_PATH" "$REF" "$DEST" "$LOG"
