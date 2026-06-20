#!/usr/bin/env bash
# deploy_serve — deploy the cyberware govd engine as a local container (proven pathway). Structured JSON output.
#   builds the image only if absent, replaces any container by the same NAME (stop + rm, no -f), runs fresh, waits for /health.
set -uo pipefail
: "${CONTEXT_DIR:?}" "${RECORD_STORE:?}"
IMAGE="${IMAGE:-cyberware:local}"
NAME="${NAME:-cyberware}"
PORT="${PORT:-5773}"
VOLUME="${VOLUME:-cyberware-govd}"
LOG="${RECORD_STORE%/}/deploy.log"
OUT="${RECORD_STORE%/}/deploy.json"
HEALTH_FILE="${RECORD_STORE%/}/health.json"
: > "$LOG"

# 1. build the image only if it is not already present locally
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "build $IMAGE from $CONTEXT_DIR" >> "$LOG"
  docker build -t "$IMAGE" "$CONTEXT_DIR" >> "$LOG" 2>&1
fi

# 2. replace any existing container by this NAME (stop + rm, no -f -> oversight clean)
docker stop "$NAME" >> "$LOG" 2>&1 || true
docker rm "$NAME" >> "$LOG" 2>&1 || true

# 3. run fresh; bind the data volume so the ledger persists across restarts.
#    the monitor token is NEVER a plaintext var — read it from a *_FILE pointer at runtime (cat reads the file).
TOKEN=""
[ -n "${TOKEN_FILE:-}" ] && TOKEN="$(cat "$TOKEN_FILE")"
docker run -d -p "${PORT}:5773" -v "${VOLUME}:/data/govd" ${TOKEN:+-e GOVD_MONITOR_TOKEN="$TOKEN"} --name "$NAME" "$IMAGE" >> "$LOG" 2>&1
CID="$(docker inspect -f '{{.Id}}' "$NAME" 2>/dev/null | cut -c1-12)"

# 4. wait for /health (chipfetch validates the baked chip, then govd binds)
HEALTH=down
for _ in $(seq 1 20); do
  if curl -fsS -m 5 "http://127.0.0.1:${PORT}/health" -o "$HEALTH_FILE" 2>/dev/null; then HEALTH=ok; break; fi
  sleep 2
done
CHIP="$(grep -o '"chip_sha"[^,]*' "$HEALTH_FILE" 2>/dev/null | head -1 | sed 's/.*: *"//;s/".*//')"

printf '{"tool":"deploy_serve","status":"%s","image":"%s","container":"%s","port":%s,"health":"%s","chip_sha":"%s","dashboard":"http://127.0.0.1:%s/","log":"%s"}\n' \
  "$([ "$HEALTH" = ok ] && echo ok || echo fail)" "$IMAGE" "${CID:-none}" "$PORT" "$HEALTH" "${CHIP:-unknown}" "$PORT" "$LOG" | tee "$OUT"
[ "$HEALTH" = ok ]
