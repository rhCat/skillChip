#!/usr/bin/env bash
# cws_repin — porter: runs the Python core (cws_repin.py), which reads its inputs from the environment.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/cws_repin.py"
