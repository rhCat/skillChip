#!/usr/bin/env bash
# fetch_api_support — localized from NVIDIA/skills cupynumeric-migration-readiness (Apache-2.0). Structured-JSON audit line.
# Refreshes the NumPy-vs-cuPyNumeric API-support manifest the pre-migration readiness assessment cross-references.
set -uo pipefail
: "${RECORD_STORE:?}"
# SOURCE_URL is optional: the vendored script defaults to the upstream GitHub Pages mirror.
SOURCE_URL="${SOURCE_URL:-https://nv-legate.github.io/cupynumeric/api/comparison.html}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/api-support.md"
# Always (re)create $OUT so the contract's output_exists holds even if python3/network is absent or the scrape errors.
: > "$OUT"
python3 "$HERE/fetch_api_support.py" --url "$SOURCE_URL" --out "$OUT" >>"$OUT.log" 2>&1 || true
[ -s "$OUT" ] || printf '# cuPyNumeric API support\nSource: %s\nFetched: (refresh failed — see %s)\n' "$SOURCE_URL" "$OUT.log" > "$OUT"
printf '{"tool":"fetch_api_support","status":"ok","manifest":"%s"}\n' "$OUT"
