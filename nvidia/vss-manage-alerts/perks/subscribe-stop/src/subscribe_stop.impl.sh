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
# subscribe_stop.impl.sh — delete (stop) a realtime alert rule on Alert Bridge
# (Workflow D / references/alert-subscriptions.md, "Stop Realtime Alert Rule" → "On Yes — Execute Deletion").
#
#   DELETE http://<HOST_IP>:9080/api/v1/realtime/<RULE_ID>
#
# The skill's user-facing yes/no confirmation gate is enforced by the caller
# BEFORE this op runs; this script performs the already-confirmed deletion.
#
# Usage:
#   subscribe_stop.impl.sh <base-url> <rule_id>
#
# Exit codes: 0 = HTTP 2xx (deleted), 1 = usage error, 2 = request failed / non-2xx.

set -uo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '20,33p' "$0"; exit 0
fi

base_url="${1:-}"
rule_id="${2:-}"
[[ -n "$base_url" && -n "$rule_id" ]] || { echo "ERROR: base-url and rule_id are required" >&2; exit 1; }
base_url="${base_url%/}"
endpoint="${base_url}/api/v1/realtime/${rule_id}"

tmp="$(mktemp)"
code="$(curl -s -o "$tmp" -w '%{http_code}' \
        --max-time 30 --connect-timeout 5 \
        -X DELETE "$endpoint" 2>/dev/null)" || code=""
resp="$(cat "$tmp" 2>/dev/null)"; rm -f "$tmp"
# Normalize: keep the last 3-digit status token; default 000 on connect failure.
code="$(printf '%s' "$code" | grep -oE '[0-9]{3}' | tail -1)"; [ -n "$code" ] || code="000"

echo "endpoint=${endpoint}"
echo "http_code=${code}"
echo "response=${resp}"

case "$code" in
  2*)  exit 0 ;;
  404) echo "NOTE: rule no longer active (HTTP 404) — nothing to stop" >&2; exit 2 ;;
  *)   echo "ERROR: Alert Bridge stop failed (HTTP ${code})" >&2; exit 2 ;;
esac
