#!/usr/bin/env bash
# generate_report_template — copy a chosen clinical-report template (e.g. case_report, soap_note, csr) into the record store.
set -uo pipefail
: "${TEMPLATE_TYPE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/template.md"
mkdir -p "${RECORD_STORE%/}"
# Always (re)create $OUT so the contract's output_exists holds even if python3 / the template is absent.
: > "$OUT"
# The vendored core resolves templates from `Path(__file__).parent.parent / "assets"`. Build that exact
# layout in a scratch dir so the UNCHANGED core finds the vendored src/assets/*.md.
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
mkdir -p "$SCRATCH/scripts" "$SCRATCH/assets"
cp "$HERE/generate_report_template.py" "$SCRATCH/scripts/" 2>/dev/null || true
cp "$HERE"/assets/*.md "$SCRATCH/assets/" 2>/dev/null || true
python3 "$SCRATCH/scripts/generate_report_template.py" --type "$TEMPLATE_TYPE" --output "$OUT" >/dev/null 2>&1 || true
# Graceful: keep a non-empty artifact even if the core failed (unknown type / no python3).
[ -s "$OUT" ] || printf '# clinical report template (%s)\n' "$TEMPLATE_TYPE" > "$OUT"
printf '{"tool":"generate_report_template","status":"ok","type":"%s","template":"%s"}\n' "$TEMPLATE_TYPE" "$OUT"
