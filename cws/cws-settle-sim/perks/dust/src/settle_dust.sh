#!/usr/bin/env bash
# settle_dust — porter: P6-T15 adapter-boundary rounding rule + dust account validator.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/settle_dust.py"
