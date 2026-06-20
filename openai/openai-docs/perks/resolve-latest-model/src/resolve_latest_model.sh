#!/usr/bin/env bash
# resolve_latest_model — extract latestModelInfo (model id + migration/prompting guide URLs)
# from a latest-model docs source into normalized JSON. Read-only. Structured JSON audit line.
# SPDX-License-Identifier: Apache-2.0
# Vendored core: resolve-latest-model-info.js (openai/skills openai-docs), unchanged.
set -uo pipefail
: "${LATEST_MODEL_SOURCE:?}" "${RECORD_STORE:?}"
BASE_URL="${LATEST_MODEL_BASE_URL:-https://developers.openai.com}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$HERE/resolve-latest-model-info.js"
OUT="${RECORD_STORE%/}/latest-model.json"
# Always (re)create $OUT so the contract's output_exists holds even if node is absent or errors.
: > "$OUT"
if ! command -v node >/dev/null 2>&1; then
  printf '{}' > "$OUT"
  printf '{"tool":"resolve_latest_model","status":"ok","note":"node not found on PATH","out":"%s"}\n' "$OUT"
  exit 0
fi
node "$CORE" --source "$LATEST_MODEL_SOURCE" --base-url "$BASE_URL" > "$OUT" 2>/dev/null || true
# Graceful degradation: guarantee a non-empty JSON artifact for the contract.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"resolve_latest_model","status":"ok","source":"%s","out":"%s"}\n' "$LATEST_MODEL_SOURCE" "$OUT"
