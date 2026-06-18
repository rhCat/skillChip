#!/usr/bin/env bash
# rt_ledger_tamper — porter: runs the Python core (rt_ledger_tamper.py), which reads its inputs from the environment.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/rt_ledger_tamper.py"
