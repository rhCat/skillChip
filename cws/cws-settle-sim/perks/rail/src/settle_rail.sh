#!/usr/bin/env bash
# settle_rail — porter: SV-6 settlement validator (the settle-time tax rail).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/settle_rail.py"
