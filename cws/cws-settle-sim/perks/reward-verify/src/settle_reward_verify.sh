#!/usr/bin/env bash
# settle_reward_verify porter
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/settle_reward_verify.py"
