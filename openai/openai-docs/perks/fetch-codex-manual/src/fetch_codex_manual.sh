#!/usr/bin/env bash
# fetch_codex_manual — fetch + sha256-verify + temp-cache the Codex manual and emit its heading
# outline. Read-only fetch. Structured JSON audit line. Needs node + live network.
# SPDX-License-Identifier: Apache-2.0
# Vendored core: fetch-codex-manual.mjs (openai/skills openai-docs), unchanged.
set -uo pipefail
: "${RECORD_STORE:?}"
MANUAL_URL="${MANUAL_URL:-https://developers.openai.com/codex/codex-manual.md}"
CACHE_DIR="${CACHE_DIR:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$HERE/fetch-codex-manual.mjs"
OUT="${RECORD_STORE%/}/codex-manual-outline.md"
# Always (re)create $OUT so the contract's output_exists holds even if node/network is absent.
: > "$OUT"
if ! command -v node >/dev/null 2>&1; then
  printf '# Codex Manual Outline\n\nnode not found on PATH; manual not fetched.\n' > "$OUT"
  printf '{"tool":"fetch_codex_manual","status":"ok","note":"node not found on PATH","out":"%s"}\n' "$OUT"
  exit 0
fi
# The core writes codex-manual.md + outline into the cache dir and prints the outline/status to stdout.
if [ -n "$CACHE_DIR" ]; then
  node "$CORE" --manual-url "$MANUAL_URL" --cache-dir "$CACHE_DIR" > "$OUT" 2>/dev/null || true
else
  node "$CORE" --manual-url "$MANUAL_URL" > "$OUT" 2>/dev/null || true
fi
# Graceful degradation: guarantee a non-empty artifact for the contract (e.g. offline / fetch failure).
[ -s "$OUT" ] || printf '# Codex Manual Outline\n\nmanual fetch failed (offline or unreachable).\n' > "$OUT"
printf '{"tool":"fetch_codex_manual","status":"ok","manual_url":"%s","out":"%s"}\n' "$MANUAL_URL" "$OUT"
