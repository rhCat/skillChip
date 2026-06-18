#!/usr/bin/env bash
# settle_simulate — P6-T18 umbrella: storm + manipulate + dispute.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/settle_simulate.py"
