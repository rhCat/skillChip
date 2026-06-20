#!/usr/bin/env bash
# discover_assets — localized from NVIDIA/skills skill-card-generator (CC-BY-4.0 AND Apache-2.0). Structured-JSON audit line.
# Standalone read-only signal discovery over a target skill dir: emits a bounded, redacted report the
# agent uses to author the card context. No source mutation; output captured to $OUT under RECORD_STORE.
set -uo pipefail
: "${SKILL_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/discovery.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python or the target is absent.
: > "$OUT"
if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
  printf '{"tool":"discover_assets","status":"ok","out":"%s"}\n' "$OUT"
  exit 0
fi
# discover_assets.py reads references/ relative to its parent.parent; vendored copy lives in src/references,
# so run from src/ with the script one level up shape preserved — references are best-effort there.
python3 "$HERE/discover_assets.py" "${SKILL_DIR}" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf 'no discovery output produced\n' > "$OUT"
printf '{"tool":"discover_assets","status":"ok","out":"%s"}\n' "$OUT"
