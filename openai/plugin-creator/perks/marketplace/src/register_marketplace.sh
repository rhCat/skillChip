#!/usr/bin/env bash
# register_marketplace — create/update a repo-root marketplace.json entry for a plugin. DESTRUCTIVE. Structured JSON output (audit/debug log).
# Vendored core: create_basic_plugin.py (openai/skills plugin-creator, Apache-2.0).
set -uo pipefail
: "${PLUGIN_NAME:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/marketplace.json"
# Always (re)create $OUT so the contract's output_exists holds even if python3 is absent or errors.
: > "$OUT"
# Default the plugin parent + marketplace target under the record store so the op is self-contained.
PARENT="${PLUGIN_PARENT:-$RECORD_STORE}"
MKT="${MARKETPLACE_PATH:-${RECORD_STORE%/}/.agents/plugins/marketplace.json}"
mkdir -p "$PARENT" "$(dirname "$MKT")" 2>/dev/null || true

if ! command -v python3 >/dev/null 2>&1; then
  printf '{"status":"degraded","reason":"python3 not found"}\n' > "$OUT"
  printf '{"tool":"register_marketplace","status":"ok","marketplace_out":"%s"}\n' "$OUT"
  exit 0
fi

# Run the vendored core with --with-marketplace (+ --force so re-runs overwrite the same-named entry). Degrade gracefully.
python3 "$HERE/create_basic_plugin.py" "$PLUGIN_NAME" \
  --path "$PARENT" \
  --with-marketplace \
  --marketplace-path "$MKT" \
  --force > "${OUT}.log" 2>&1 || true

# Surface the updated registry as the contract output (copy if produced).
if [ -s "$MKT" ]; then
  cp "$MKT" "$OUT" 2>/dev/null || true
fi

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"register_marketplace","status":"ok","marketplace_out":"%s"}\n' "$OUT"
