#!/usr/bin/env python3
"""rt_gvisor_tier — kernel red-team perk (P2-T04, community tier): assert the gVisor (runsc) backend behind the
SAME value-free SandboxProfile driver enforces the SAME confinement as bwrap — it may NEVER weaken the
boundary — and that the community tier is the no-secrets floor (a community manifest requesting a credential is
refused at both the schema and the runtime). The rendering + tier checks are PURE (provable on any host); the
LIVE attack corpus under each backend is host-gated (bwrap=is_available, runsc=runsc_available) and recorded
honestly. Writes redteam.json; exit 0 iff the boundary held."""
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "exec")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.exec import sandbox  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = sandbox.community_tier_selftest()
    rec = {"tool": "rt_gvisor_tier", "family": "sandbox", "held": r["ok"], "refused": r["ok"],
           "seam_parity": r["seam_parity"], "gvisor_no_weaken": r["gvisor_no_weaken"],
           "network_grant_tracks": r["network_grant_tracks"], "no_secrets_tier": r["no_secrets_tier"],
           "bwrap_live": r["bwrap_live"], "runsc_live": r["runsc_live"],
           "detail": "gVisor seam == bwrap confinement (never weaker); community tier refuses secrets"}
    with open(os.path.join(store, "redteam.json"), "w") as f:
        json.dump(rec, f, indent=2)
    print(json.dumps(rec))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
