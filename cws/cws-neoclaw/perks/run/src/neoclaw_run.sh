#!/usr/bin/env bash
# neoclaw_run — porter: forward a governed claim to a node (runs the Python core, neoclaw_run.py).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/neoclaw_run.py"
