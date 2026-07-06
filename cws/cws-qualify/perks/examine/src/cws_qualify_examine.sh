#!/usr/bin/env bash
# cws_qualify_examine — porter: runs the Python core (cws_qualify_examine.py), which reads its inputs from the environment.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/cws_qualify_examine.py"
