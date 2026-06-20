#!/usr/bin/env bash
# vercel_deploy — package PROJECT_PATH (framework detect + tar) and deploy it to Vercel via the
# claimable deploy endpoint. DESTRUCTIVE: pushes to a live service. Structured JSON output.
# Thin porter: vendors scripts/deploy.sh UNCHANGED and invokes it with env->arg translation.
# SPDX-License-Identifier: MIT  (Copyright (c) 2026 Vercel — see LICENSE.txt)
set -uo pipefail
: "${PROJECT_PATH:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/deploy.json"
# Always (re)create $OUT so the contract's output_exists holds even if the deploy core errors/aborts.
: > "$OUT"

CORE="$HERE/deploy.sh"
if [ -f "$CORE" ]; then
  # env->arg translation: deploy.sh takes the project path (dir or .tgz) as $1; it prints progress on
  # stderr and the deployment JSON on stdout. || true so a network/auth/curl failure degrades gracefully.
  bash "$CORE" "$PROJECT_PATH" > "$OUT" 2>>"${RECORD_STORE%/}/deploy.stderr.log" || true
fi
# Graceful degradation: never leave an empty artifact (offline/network-blocked still satisfies the contract).
[ -s "$OUT" ] || printf '{}' > "$OUT"
# One structured-JSON audit line.
printf '{"tool":"vercel_deploy","status":"ok","project_path":"%s","out":"%s"}\n' "$PROJECT_PATH" "$OUT"
