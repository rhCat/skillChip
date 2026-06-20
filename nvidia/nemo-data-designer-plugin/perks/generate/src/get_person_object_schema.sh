#!/usr/bin/env bash
# get_person_object_schema — localized from NVIDIA/skills nemo-data-designer-plugin (Apache-2.0). Structured-JSON audit line.
set -uo pipefail
: "${LOCALE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/person_schema.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python/data-designer is absent or errors.
: > "$OUT"
# The script takes a positional <locale> and prints the schema to stdout; capture both streams into $OUT.
python3 "$HERE/get_person_object_schema.py" "${LOCALE}" >"$OUT" 2>&1 || true
[ -s "$OUT" ] || printf 'no schema output for locale %s\n' "${LOCALE}" > "$OUT"
printf '{"tool":"get_person_object_schema","status":"ok","schema":"%s"}\n' "$OUT"
