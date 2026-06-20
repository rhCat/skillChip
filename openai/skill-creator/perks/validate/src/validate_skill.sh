#!/usr/bin/env bash
# validate_skill — porter: validates a skill's SKILL.md frontmatter via the vendored quick_validate.py
# core (read-only — checks name/description presence, types, hyphen-case naming). Structured JSON output.
set -uo pipefail
: "${SKILL_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/validate.out"
# Always (re)create $OUT so the contract's output_exists holds even if python3/pyyaml is absent or errors.
: > "$OUT"
# env -> arg translation: SKILL_DIR is the sole positional arg of quick_validate.py.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/quick_validate.py" "$SKILL_DIR" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"validate_skill","status":"ok","skill_dir":"%s","report":"%s"}\n' "$SKILL_DIR" "$OUT"
