#!/usr/bin/env bash
# settle_credits — porter: SV-6 settlement validator (credit-based usage billing).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/settle_credits.py"
