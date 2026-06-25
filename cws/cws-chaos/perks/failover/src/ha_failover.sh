#!/usr/bin/env bash
# ha_failover — P5-T04 active-passive govd + advisory-lock lease drill.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/ha_failover.py"
