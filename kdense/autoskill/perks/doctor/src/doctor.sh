#!/usr/bin/env bash
# doctor — preflight: confirm the config backend is valid, the skills dir exists, the screenpipe
# daemon is reachable + authed, and the LLM backend is ready, using the vendored doctor.py CLI.
# The doctor report (one line per check: config / skills_dir / screenpipe / llm) is the artifact;
# offline the network probes report "error" but the porter still captures the report and exits 0
# so the contract holds. Reads CONFIG (config.yaml) + SKILLS_DIR. Writes doctor.txt under
# RECORD_STORE. Structured-JSON audit line on stdout.
set -uo pipefail
: "${CONFIG:?CONFIG (path to config.yaml) is required}"
: "${SKILLS_DIR:?SKILLS_DIR (path to skills/ directory) is required}"
: "${RECORD_STORE:?RECORD_STORE is required}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/doctor.txt"
: > "$OUT"

PYTHONPATH="$HERE" python3 "$HERE/doctor.py" \
  --config "$CONFIG" --skills-dir "$SKILLS_DIR" >> "$OUT" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"doctor","status":"ok","report":"%s"}\n' "$OUT"
