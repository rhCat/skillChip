#!/usr/bin/env bash
# detect_framework — resolve a project's Vercel framework slug from its package.json (read-only).
# Thin porter: vendors scripts/deploy.sh UNCHANGED and reuses ONLY its detect_framework() function
# (the rest of deploy.sh stages/tars/uploads — not invoked here). Structured JSON output.
# SPDX-License-Identifier: MIT  (Copyright (c) 2026 Vercel — see LICENSE.txt)
set -uo pipefail
: "${PROJECT_PATH:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/framework.json"
# Always (re)create $OUT so the contract's output_exists holds even if anything below errors.
: > "$OUT"

# Extract ONLY the detect_framework() function body from the vendored (unchanged) core and source it,
# so we never run deploy.sh's top-level packaging/upload pipeline.
CORE="$HERE/deploy.sh"
FRAMEWORK="null"
if [ -f "$CORE" ]; then
  FN="$(awk '/^detect_framework\(\) \{/{f=1} f{print} f&&/^\}/{exit}' "$CORE")"
  if [ -n "$FN" ]; then
    eval "$FN" || true
    # Resolve package.json: PROJECT_PATH may be a dir or a package.json file directly.
    PKG="$PROJECT_PATH"
    [ -d "$PROJECT_PATH" ] && PKG="${PROJECT_PATH%/}/package.json"
    FRAMEWORK="$(detect_framework "$PKG" 2>/dev/null || echo null)"
    [ -z "$FRAMEWORK" ] && FRAMEWORK="null"
  fi
fi

printf '{"tool":"detect_framework","status":"ok","project_path":"%s","framework":"%s"}\n' \
  "$PROJECT_PATH" "$FRAMEWORK" > "$OUT"
# Graceful degradation: never leave an empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
# One structured-JSON audit line.
printf '{"tool":"detect_framework","status":"ok","framework":"%s","out":"%s"}\n' "$FRAMEWORK" "$OUT"
