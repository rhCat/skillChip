#!/usr/bin/env bash
# synthesize — LLM judge: classify each cluster as reuse / compose / novel and draft a SKILL.md
# body, using the vendored synthesize.py + backends.py. Sends ONLY redacted cluster summaries to
# the configured backend (local LM Studio by default; claude/foundry opt-in). Requires a reachable
# LLM backend; offline the porter degrades gracefully, writing a valid verdicts file with each
# cluster marked status "skipped" (no backend). Reads MATCHES (matches.json from the match perk)
# + CONFIG (config.yaml). Writes verdicts.json under RECORD_STORE. Structured-JSON audit line.
set -uo pipefail
: "${MATCHES:?MATCHES (path to matches.json) is required}"
: "${CONFIG:?CONFIG (path to config.yaml) is required}"
: "${RECORD_STORE:?RECORD_STORE is required}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/verdicts.json"
: > "$OUT"

PYTHONPATH="$HERE" python3 - "$MATCHES" "$CONFIG" "$OUT" <<'PY' || true
import json, sys
from synthesize import synthesize

matches_path, config_path, dst = sys.argv[1:4]

try:
    payload = json.load(open(matches_path))
except Exception:
    payload = {}
matches = payload.get("matches", [])

# Build the backend from config; if config/backend libs are missing or the backend
# is unreachable we fall back to a sentinel that yields skipped verdicts (offline).
backend = None
try:
    import yaml
    from backends import make_backend
    config = yaml.safe_load(open(config_path).read()) or {}
    backend = make_backend(config)
except Exception:
    backend = None

verdicts = []
for m in matches:
    cluster = {
        "apps": m.get("apps", []),
        "session_count": m.get("session_count", 0),
        "total_duration_seconds": m.get("total_duration_seconds", 0),
        "example_titles": m.get("example_titles", []),
    }
    top_k = m.get("top_k", [])
    if backend is None:
        verdicts.append({"apps": cluster["apps"], "status": "skipped",
                         "reason": "no reachable LLM backend"})
        continue
    try:
        decision = synthesize(cluster, top_k, backend=backend)
        decision["apps"] = cluster["apps"]
        decision["status"] = "ok"
        verdicts.append(decision)
    except Exception as e:
        verdicts.append({"apps": cluster["apps"], "status": "error",
                         "reason": str(e)})

with open(dst, "w") as fh:
    json.dump({"verdicts": verdicts}, fh, indent=2)
PY

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"synthesize","status":"ok","verdicts":"%s"}\n' "$OUT"
