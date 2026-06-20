#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2025-2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# subscribe_create.impl.sh — POST a realtime alert rule to Alert Bridge
# (Workflow D / references/alert-subscriptions.md, "Create Realtime Alert Rule").
#
# Builds the canonical Alert Bridge payload and POSTs it to
#   http://<HOST_IP>:9080/api/v1/realtime
# Required API fields: live_stream_url, alert_type, prompt. The sensor_id /
# sensor_name / system_prompt / chunk fields are skill conventions sent on every
# create for reproducibility. Emits the HTTP status code and response body.
#
# Usage:
#   subscribe_create.impl.sh <base-url> <live_stream_url> <alert_type> <prompt> \
#       [sensor_id] [sensor_name] [system_prompt] [chunk_duration] [chunk_overlap]
#
# Exit codes: 0 = HTTP 2xx (rule created), 1 = usage error, 2 = request failed / non-2xx.

set -uo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '20,33p' "$0"; exit 0
fi

base_url="${1:-}"
live_stream_url="${2:-}"
alert_type="${3:-}"
prompt="${4:-}"
sensor_id="${5:-}"
sensor_name="${6:-}"
system_prompt="${7:-Answer yes or no}"
chunk_duration="${8:-30}"
chunk_overlap="${9:-5}"

[[ -n "$base_url" && -n "$live_stream_url" && -n "$alert_type" && -n "$prompt" ]] || {
  echo "ERROR: base-url, live_stream_url, alert_type, and prompt are required" >&2
  exit 1
}
base_url="${base_url%/}"
endpoint="${base_url}/api/v1/realtime"

# Build the JSON body with python3 so values containing quotes/backslashes/newlines
# cannot escape the JSON string and inject extra fields.
body="$(python3 -c '
import json, sys
ls, st, sn, at, pr, sp = sys.argv[1:7]
cd, co = int(sys.argv[7]), int(sys.argv[8])
payload = {
    "live_stream_url": ls,
    "alert_type": at,
    "prompt": pr,
    "system_prompt": sp,
    "chunk_duration": cd,
    "chunk_overlap_duration": co,
}
if st:
    payload["sensor_id"] = st
if sn:
    payload["sensor_name"] = sn
print(json.dumps(payload))
' "$live_stream_url" "$sensor_id" "$sensor_name" "$alert_type" "$prompt" "$system_prompt" "$chunk_duration" "$chunk_overlap")" || {
  echo "ERROR: failed to build payload" >&2
  exit 1
}

tmp="$(mktemp)"
code="$(printf '%s' "$body" \
  | curl -s -o "$tmp" -w '%{http_code}' \
         --max-time 30 --connect-timeout 5 \
         -X POST "$endpoint" \
         -H 'Content-Type: application/json' \
         --data-binary @- 2>/dev/null)" || code=""
resp="$(cat "$tmp" 2>/dev/null)"; rm -f "$tmp"
# Normalize: keep the last 3-digit status token; default 000 on connect failure.
code="$(printf '%s' "$code" | grep -oE '[0-9]{3}' | tail -1)"; [ -n "$code" ] || code="000"

echo "endpoint=${endpoint}"
echo "http_code=${code}"
echo "response=${resp}"

case "$code" in
  2*) exit 0 ;;
  *)  echo "ERROR: Alert Bridge create failed (HTTP ${code})" >&2; exit 2 ;;
esac
