#!/usr/bin/env bash
# cws_observe_redeem — porter: runs the Python core (cws_observe_redeem.py), which reads its inputs from the environment.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/cws_observe_redeem.py"
