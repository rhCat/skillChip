#!/usr/bin/env bash
# fleet_deploy — porter: runs the Python core (fleet_deploy.py), which reads its inputs from the environment.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/fleet_deploy.py"
