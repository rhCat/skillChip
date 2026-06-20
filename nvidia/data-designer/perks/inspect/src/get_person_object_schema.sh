#!/usr/bin/env bash
# get_person_object_schema — localized from NVIDIA/skills data-designer (Apache-2.0). Structured-JSON audit line.
# Inspects a locale's managed persona dataset and lists its PII + synthetic-persona fields.
# The vendored .py takes the locale as a positional arg and prints the schema to stdout, so
# we redirect stdout to $OUT. Always (re)create $OUT so the contract's output_exists holds
# even if python3, the data-designer package, or the locale's managed asset is absent.
set -uo pipefail
: "${LOCALE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/person_schema.txt"
: > "$OUT"
if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
  printf '{"tool":"get_person_object_schema","status":"ok","out":"%s"}\n' "$OUT"
  exit 0
fi
python3 "$HERE/get_person_object_schema.py" "${LOCALE}" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf 'no output produced for locale %s\n' "${LOCALE}" >> "$OUT"
printf '{"tool":"get_person_object_schema","status":"ok","out":"%s"}\n' "$OUT"
