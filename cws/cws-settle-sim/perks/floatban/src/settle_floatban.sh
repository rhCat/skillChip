#!/usr/bin/env bash
# settle_floatban — porter: the Money-type + float-ban validator (P6-T01).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/settle_floatban.py"
