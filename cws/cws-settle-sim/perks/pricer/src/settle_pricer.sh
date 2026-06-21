#!/usr/bin/env bash
# settle_pricer — porter: SV-6 settlement validator (the plan pricer).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/settle_pricer.py"
