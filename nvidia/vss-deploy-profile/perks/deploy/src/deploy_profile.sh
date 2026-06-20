#!/usr/bin/env bash
# deploy_profile — localized from NVIDIA/skills vss-deploy-profile (Apache-2.0). Structured-JSON audit line.
# Drives the documented VSS deploy flow: read-only credential probe, cp .env -> generated.env,
# docker compose config > resolved.yml, normalize_resolved_yml.py, then docker compose up -d.
# DESTRUCTIVE: brings up the VSS stack, pulls NIM images, mutates host infrastructure.
set -uo pipefail
: "${REPO:?}" "${PROFILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/deploy.json"
LOG="${OUT}.log"
# Always (re)create $OUT so the contract's output_exists holds even if a tool is absent or errors.
: > "$OUT"
: > "$LOG"

DOCKER_DIR="${REPO%/}/deploy/docker"
PROF_DIR="${DOCKER_DIR}/developer-profiles/dev-profile-${PROFILE}"
ENV_SRC="${PROF_DIR}/.env"
ENV_GEN="${PROF_DIR}/generated.env"
RESOLVED="${DOCKER_DIR}/resolved.yml"
status="ok"
step="start"

{
  # Step 0a — read-only credential gate (never writes generated.env)
  step="credentials"
  bash "$HERE/check_credentials.sh" || true

  # Step 1c — initialize generated.env from a fresh copy of the source .env
  step="init_generated_env"
  if [ -f "$ENV_SRC" ]; then
    cp "$ENV_SRC" "$ENV_GEN" || true
  else
    echo "ENV_SRC not found: $ENV_SRC" >&2
    status="degraded"
  fi

  # Step 3 — dry-run: resolve compose into resolved.yml
  step="compose_config"
  if command -v docker >/dev/null 2>&1 && [ -f "$ENV_GEN" ]; then
    ( cd "$DOCKER_DIR" && docker compose --env-file "$ENV_GEN" config > "$RESOLVED" ) || status="degraded"
  else
    echo "docker not found or generated.env missing — skipping compose config" >&2
    status="degraded"
  fi

  # Step 3d — strip dangling optional depends_on from resolved.yml (MUST run before up -d)
  step="normalize"
  if [ -f "$RESOLVED" ]; then
    python3 "$HERE/normalize_resolved_yml.py" "$RESOLVED" || status="degraded"
  fi

  # Step 5 — deploy (DESTRUCTIVE). --env-file is mandatory.
  step="up"
  if command -v docker >/dev/null 2>&1 && [ -f "$RESOLVED" ] && [ -f "$ENV_GEN" ]; then
    ( cd "$DOCKER_DIR" && docker compose --env-file "$ENV_GEN" -f "$RESOLVED" up -d ) || status="degraded"
  else
    echo "docker not found or resolved.yml/generated.env missing — skipping up -d" >&2
    status="degraded"
  fi
} >>"$LOG" 2>&1 || true

printf '{"tool":"deploy_profile","status":"%s","profile":"%s","repo":"%s","resolved":"%s","log":"%s","out":"%s"}\n' \
  "$status" "$PROFILE" "$REPO" "$RESOLVED" "$LOG" "$OUT" | tee "$OUT"
