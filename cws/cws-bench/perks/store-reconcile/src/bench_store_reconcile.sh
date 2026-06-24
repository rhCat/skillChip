#!/usr/bin/env bash
# bench_store_reconcile — porter: P5-T01 Store-interface + JSONL-reconciler validator.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/bench_store_reconcile.py"
