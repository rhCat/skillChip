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

"""render_notification — offline renderer for VSS incident notifications.

Thin wrapper that exercises the *pure* formatting functions vendored from the
alert-notify backends (``build_slack_blocks`` from ``slack_notifier``,
``build_dashboard_message`` from ``open_claw_dashboard_notifier``, and
``build_test_incident`` from ``incident_utils``). Given an incident JSON file
(or the synthetic test incident), it produces the Slack Block Kit payload and
the OpenClaw Dashboard markdown that the live relay would post — without any
network, Slack token, or running server. Used to preview / validate how an
incident will render before wiring up notifications.

The backend modules import ``slack_sdk`` and ``websockets`` at module scope for
their *Notifier classes*, which are unrelated to the pure ``build_*`` helpers.
To run those helpers offline without modifying the vendored sources, this
wrapper registers minimal stub modules for those optional third-party imports
before importing the backends.
"""

from __future__ import annotations

import json
import sys
import types
from pathlib import Path


def _ensure_stub(name: str, attrs: dict) -> None:
    """Register a stub module under *name* if the real one is unavailable."""
    if name in sys.modules:
        return
    try:
        __import__(name)
        return
    except Exception:
        pass
    mod = types.ModuleType(name)
    for attr, value in attrs.items():
        setattr(mod, attr, value)
    sys.modules[name] = mod


def _install_optional_stubs() -> None:
    # slack_sdk.WebClient + slack_sdk.errors.SlackApiError (only the names the
    # vendored slack_notifier references at import time).
    class _Stub:  # noqa: D401 - placeholder
        def __init__(self, *a, **k):
            pass

    _ensure_stub("slack_sdk", {"WebClient": _Stub})
    _ensure_stub("slack_sdk.errors", {"SlackApiError": type("SlackApiError", (Exception,), {})})
    if "slack_sdk" in sys.modules and not hasattr(sys.modules["slack_sdk"], "errors"):
        sys.modules["slack_sdk"].errors = sys.modules["slack_sdk.errors"]
    # websockets (open_claw_dashboard_notifier imports the top-level package).
    _ensure_stub("websockets", {"connect": lambda *a, **k: None})


def main() -> int:
    here = Path(__file__).resolve().parent
    sys.path.insert(0, str(here))
    _install_optional_stubs()

    out_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else here
    incident_path = sys.argv[2] if len(sys.argv) > 2 else ""

    from incident_utils import build_test_incident

    if incident_path:
        incident = json.loads(Path(incident_path).read_text())
    else:
        incident = build_test_incident()

    result: dict = {"tool": "render_notification", "status": "ok"}

    try:
        from slack_notifier import build_slack_blocks

        blocks, fallback_text, color = build_slack_blocks(incident)
        result["slack"] = {
            "fallback_text": fallback_text,
            "color": color,
            "blocks": blocks,
        }
    except Exception as exc:  # pragma: no cover - degrade gracefully
        result["slack_error"] = str(exc)
        result["status"] = "partial"

    try:
        from open_claw_dashboard_notifier import build_dashboard_message

        result["dashboard_markdown"] = build_dashboard_message(incident)
    except Exception as exc:  # pragma: no cover - degrade gracefully
        result["dashboard_error"] = str(exc)
        result["status"] = "partial"

    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "rendered.json"
    out_file.write_text(json.dumps(result, indent=2))
    print(json.dumps({"tool": "render_notification", "status": result["status"], "out": str(out_file)}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
