#!/usr/bin/env bash
# neoclaw_discover — porter: runs the Python core (neoclaw_discover.py), which reads its inputs from the environment.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/neoclaw_discover.py"
