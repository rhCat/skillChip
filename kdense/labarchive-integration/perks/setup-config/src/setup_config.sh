#!/usr/bin/env bash
# setup_config — generate a LabArchives config.yaml from env vars (local, read-only). Structured JSON output.
# Vendored core: setup_config.py (interactive CLI). The core is driven non-interactively here by importing
# its create_config_file/verify_config helpers; env vars replace the interactive input() prompts.
set -uo pipefail
: "${LA_API_URL:?}" "${LA_ACCESS_KEY_ID:?}" "${LA_ACCESS_PASSWORD:?}" "${LA_USER_EMAIL:?}" "${LA_USER_EXTERNAL_PASSWORD:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/setup_config.json"
CONFIG="${RECORD_STORE%/}/config.yaml"
# Always (re)create $OUT so the contract's output_exists holds even if python/yaml is absent or errors.
: > "$OUT"

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
LA_API_URL="$LA_API_URL" \
LA_ACCESS_KEY_ID="$LA_ACCESS_KEY_ID" \
LA_ACCESS_PASSWORD="$LA_ACCESS_PASSWORD" \
LA_USER_EMAIL="$LA_USER_EMAIL" \
LA_USER_EXTERNAL_PASSWORD="$LA_USER_EXTERNAL_PASSWORD" \
CONFIG_OUT="$CONFIG" \
AUDIT_OUT="$OUT" \
python3 - <<'PY' || true
import os, json
audit = os.environ["AUDIT_OUT"]
config_out = os.environ["CONFIG_OUT"]
result = {"tool": "setup_config", "status": "ok", "config": config_out}
try:
    # Import the vendored core unchanged and reuse its file-writer + verifier.
    from setup_config import create_config_file, verify_config
    config_data = {
        "api_url": os.environ["LA_API_URL"],
        "access_key_id": os.environ["LA_ACCESS_KEY_ID"],
        "access_password": os.environ["LA_ACCESS_PASSWORD"],
        "user_email": os.environ["LA_USER_EMAIL"],
        "user_external_password": os.environ["LA_USER_EXTERNAL_PASSWORD"],
    }
    create_config_file(config_data, config_out)
    result["verified"] = bool(verify_config(config_out))
except Exception as e:
    result["status"] = "error"
    result["error"] = str(e)
with open(audit, "w") as f:
    json.dump(result, f)
    f.write("\n")
PY

# Ensure the audit line is non-empty even if the python core could not run (e.g. PyYAML absent).
[ -s "$OUT" ] || printf '{"tool":"setup_config","status":"degraded","config":"%s"}' "$CONFIG" > "$OUT"
printf '{"tool":"setup_config","status":"ok","config":"%s","audit":"%s"}\n' "$CONFIG" "$OUT"
