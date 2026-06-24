#!/usr/bin/env bash
# settle_adapter — porter: P6-T14 SettlementAdapter validator (Stripe + internal-credits seam).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/settle_adapter.py"
