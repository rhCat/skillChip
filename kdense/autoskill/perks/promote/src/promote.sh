#!/usr/bin/env bash
# promote — move a user-approved proposal directory (new-skills/<NAME> or composition-recipes/<NAME>
# under PROPOSED) into SKILLS_DIR/<NAME>/, using the vendored promote.py CLI. Local filesystem move
# only; it refuses to overwrite an existing skill. The captured promote result is the artifact.
# Reads PROPOSED (the proposed/<ts> dir), SKILLS_DIR (target skills/ dir), NAME (skill name to
# promote). Writes promote.txt under RECORD_STORE. Structured-JSON audit line on stdout.
set -uo pipefail
: "${PROPOSED:?PROPOSED (path to proposed/<ts> dir) is required}"
: "${SKILLS_DIR:?SKILLS_DIR (target skills/ dir) is required}"
: "${NAME:?NAME (skill name to promote) is required}"
: "${RECORD_STORE:?RECORD_STORE is required}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/promote.txt"
: > "$OUT"

mkdir -p "$SKILLS_DIR" 2>/dev/null || true

PYTHONPATH="$HERE" python3 "$HERE/promote.py" \
  --proposed "$PROPOSED" --skills-dir "$SKILLS_DIR" --name "$NAME" >> "$OUT" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"promote","status":"ok","report":"%s"}\n' "$OUT"
