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
# subscribe_list.impl.sh — list active realtime alert rules from Alert Bridge
# (Workflow D / references/alert-subscriptions.md, "List Active Realtime Alert Rules").
#
#   GET http://<HOST_IP>:9080/api/v1/realtime[?alert_type=<TAG>]
#
# Usage:
#   subscribe_list.impl.sh <base-url> [alert_type]
#
# Exit codes: 0 = HTTP 2xx, 1 = usage error, 2 = request failed / non-2xx.

set -uo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '20,29p' "$0"; exit 0
fi

base_url="${1:-}"
alert_type="${2:-}"
[[ -n "$base_url" ]] || { echo "ERROR: base-url is required" >&2; exit 1; }
base_url="${base_url%/}"
endpoint="${base_url}/api/v1/realtime"
[[ -n "$alert_type" ]] && endpoint="${endpoint}?alert_type=${alert_type}"

tmp="$(mktemp)"
code="$(curl -s -o "$tmp" -w '%{http_code}' \
        --max-time 30 --connect-timeout 5 \
        "$endpoint" 2>/dev/null)" || code=""
resp="$(cat "$tmp" 2>/dev/null)"; rm -f "$tmp"
# Normalize: keep the last 3-digit status token; default 000 on connect failure.
code="$(printf '%s' "$code" | grep -oE '[0-9]{3}' | tail -1)"; [ -n "$code" ] || code="000"

count=""
if [[ "$code" == 2* ]] && command -v jq >/dev/null 2>&1; then
  count="$(printf '%s' "$resp" | jq -r 'if type=="array" then length elif (.rules?|type)=="array" then (.rules|length) else 0 end' 2>/dev/null || echo "")"
fi

echo "endpoint=${endpoint}"
echo "http_code=${code}"
echo "rule_count=${count:-unknown}"
echo "response=${resp}"

case "$code" in
  2*) exit 0 ;;
  *)  echo "ERROR: Alert Bridge list failed (HTTP ${code})" >&2; exit 2 ;;
esac
