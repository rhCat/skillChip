#!/usr/bin/env bash
# settle_engine — porter: SV-6 settlement validator.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/settle_engine.py"
