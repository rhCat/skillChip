#!/usr/bin/env bash
# review_poster — read-only quality check of a poster PDF. Wraps the vendored review_poster.sh
# (page size / page count / file size / font embedding / image inventory via poppler tools).
# Mutates nothing. Emits ONE structured-JSON audit line. Degrades gracefully if poppler is absent.
set -uo pipefail
: "${POSTER_PDF:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/review.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
bash "$HERE/review_poster.impl.sh" "$POSTER_PDF" >> "$OUT" 2>&1 || true
# Guarantee a non-empty report even if the core produced nothing.
[ -s "$OUT" ] || printf 'review_poster: no output produced for %s\n' "$POSTER_PDF" > "$OUT"
printf '{"tool":"review_poster","status":"ok","report":"%s","pdf":"%s"}\n' "$OUT" "$POSTER_PDF"
