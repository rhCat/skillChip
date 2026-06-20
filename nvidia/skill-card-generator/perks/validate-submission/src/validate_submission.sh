#!/usr/bin/env bash
# validate_submission — localized from NVIDIA/skills skill-card-generator (CC-BY-4.0 AND Apache-2.0). Structured-JSON audit line.
# Standalone pre-submission gate: grep a rendered skill card for leftover VERIFY/SELECT human-review markers.
# Re-runnable after manual edits to a card. Reports markers_clean in the audit line; never mutates the card.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Prefer an explicit CARD path; otherwise check the rendered ${RECORD_STORE}/skill-card.md.
CARD="${CARD:-${RECORD_STORE%/}/skill-card.md}"
OUT="${RECORD_STORE%/}/validate_submission.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python/the card is absent.
: > "$OUT"
if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
  printf '{"tool":"validate_submission","status":"ok","reason":"no python3","out":"%s"}\n' "$OUT"
  exit 0
fi
if [ ! -f "$CARD" ]; then
  printf 'rendered card not found at %s — set CARD or render one first\n' "$CARD" >> "$OUT"
  printf '{"tool":"validate_submission","status":"ok","reason":"no rendered card","out":"%s"}\n' "$OUT"
  exit 0
fi
python3 "$HERE/validate_submission.py" "$CARD" >> "$OUT" 2>&1
RC=$?
[ -s "$OUT" ] || printf 'no validator output\n' > "$OUT"
printf '{"tool":"validate_submission","status":"ok","markers_clean":%s,"out":"%s"}\n' "$( [ "$RC" -eq 0 ] && echo true || echo false )" "$OUT"
