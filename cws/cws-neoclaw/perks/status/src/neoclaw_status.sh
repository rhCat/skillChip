#!/usr/bin/env bash
# neoclaw_status — porter: node liveness probe (runs the Python core, neoclaw_status.py).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/neoclaw_status.py"
