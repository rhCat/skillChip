#!/usr/bin/env bash
# fleet_status — porter: runs the Python core (fleet_status.py), which reads its inputs from the environment.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/fleet_status.py"
