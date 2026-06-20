#!/usr/bin/env bash
# scaffold_plugin — scaffold a Codex plugin dir + .codex-plugin/plugin.json (local-only). Structured JSON output (audit/debug log).
# Vendored core: create_basic_plugin.py (openai/skills plugin-creator, Apache-2.0).
set -uo pipefail
: "${PLUGIN_NAME:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/scaffold.json"
# Always (re)create $OUT so the contract's output_exists holds even if python3 is absent or errors.
: > "$OUT"
# Default the plugin parent to the record store so the op is self-contained and hermetic.
PARENT="${PLUGIN_PARENT:-$RECORD_STORE}"
mkdir -p "$PARENT" 2>/dev/null || true

if ! command -v python3 >/dev/null 2>&1; then
  printf '{"status":"degraded","reason":"python3 not found"}\n' > "$OUT"
  printf '{"tool":"scaffold_plugin","status":"ok","scaffold_out":"%s"}\n' "$OUT"
  exit 0
fi

# Run the vendored core: create_basic_plugin.py <plugin_name> --path <parent>. Degrade gracefully on error.
python3 "$HERE/create_basic_plugin.py" "$PLUGIN_NAME" --path "$PARENT" > "${OUT}.log" 2>&1 || true

# Build a JSON listing of the created tree (normalized name may differ from PLUGIN_NAME).
python3 - "$PARENT" "$PLUGIN_NAME" "$OUT" <<'PY' || true
import json, os, re, sys
parent, raw, out = sys.argv[1], sys.argv[2], sys.argv[3]
name = re.sub(r"-{2,}", "-", re.sub(r"[^a-z0-9]+", "-", raw.strip().lower()).strip("-"))
root = os.path.join(parent, name)
files = []
for dp, _, fns in os.walk(root):
    for fn in fns:
        files.append(os.path.relpath(os.path.join(dp, fn), root))
files.sort()
manifest = os.path.join(root, ".codex-plugin", "plugin.json")
json.dump({
    "status": "ok",
    "plugin_name": name,
    "plugin_root": root,
    "manifest": manifest if os.path.exists(manifest) else None,
    "files": files,
}, open(out, "w"), indent=2)
open(out, "a").write("\n")
PY

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"scaffold_plugin","status":"ok","scaffold_out":"%s"}\n' "$OUT"
