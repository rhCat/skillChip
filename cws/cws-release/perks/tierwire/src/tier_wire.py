#!/usr/bin/env python3
"""tier_wire — P3-T11 validator: the grant's TIER is wired to the P2 sandbox profiles (backend selection),
recorded in the catalog, and ENFORCED at the grant. Hermetic, no host backend needed. Proves the two
acceptance criteria end-to-end and writes tierwire.json; exits 0 iff all hold:

  * tier_enforced_at_grant — the grant's `sandbox_tier` deterministically selects the confinement backend exod
    hands the runner: community → gVisor (runsc); core/verified → bwrap; an UNDECLARED grant takes the operator
    floor; and the floor is MONOTONE (a runsc floor is never downgraded by a core grant). Driven through the
    REAL exod.run_step with a recording runner — the tier picks the box at the grant, before any step runs.
  * community_no_secrets_schema_and_runtime — the community tier is the no-secrets floor at BOTH the schema and
    the runtime (the P2-T04 community_tier_selftest's no_secrets_tier check).

It also proves the wiring's two ends: tier_maps/monotone_floor (the pure selection logic) and
perk_tier_flows_to_grant (a perk that DECLARES `tier: community` in perks.json → govd mints sandbox_tier=
community → the discovery catalog surfaces it)."""
import json
import os
import subprocess
import sys
import tempfile

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "exec")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey  # noqa: E402

from infra.exec import grants, sandbox  # noqa: E402
from infra.exec.exod import Exod  # noqa: E402
from infra.exec.exodverify import result_body  # noqa: E402
from infra.exec.grantverify import grant_body  # noqa: E402
from infra.govern import delegate  # noqa: E402
from infra.tool import skill_index  # noqa: E402


def _exod_selects(backend_floor):
    """Return run(sandbox_tier) -> (status, backend) — the backend exod's run_step hands the runner for a grant
    carrying `sandbox_tier`, under an operator `backend_floor`. A recording runner makes the selection visible
    without needing a real bwrap/gVisor host."""
    isk = Ed25519PrivateKey.generate()
    seen = []

    def runner(profile, argv, backend=None):
        seen.append(backend)
        return subprocess.CompletedProcess(argv, 0, "ok", "")

    ex = Exod(Ed25519PrivateKey.generate(), grant_issuer_pub=isk.public_key(), runner=runner,
              backend_floor=backend_floor)
    counter = {"n": 0}

    def run(sandbox_tier):
        counter["n"] += 1
        g = grants.mint_grant(isk, run_id="R", plan_sha="P", nbf=990, exp=1100,
                              nonce=f"n-{backend_floor}-{counter['n']}", capabilities=["run"],
                              sandbox_tier=sandbox_tier)
        seen.clear()
        env = ex.run_step(dict(run_id="R", plan_sha="P", step="1", argv=["true"], workspace="/ws", grant=g),
                          now=1000)
        return result_body(env)["status"], (seen[0] if seen else None)

    return run


def tierwire_selftest() -> dict:
    # (1) the pure tier->backend selection logic
    pure = sandbox.tier_backend_selftest()

    # (2) tier_enforced_at_grant — the grant's tier picks the backend through the REAL exod.run_step
    on_bwrap = _exod_selects("bwrap")
    on_runsc = _exod_selects("runsc")
    tier_enforced_at_grant = (
        on_bwrap("community") == ("ok", "runsc")        # community DEMANDS gVisor even under a bwrap floor
        and on_bwrap("core") == ("ok", "bwrap")
        and on_bwrap(None) == ("ok", "bwrap")           # undeclared grant → the operator floor
        and on_runsc("core") == ("ok", "runsc"))        # MONOTONE: a hardened floor is never downgraded

    # (3) community_no_secrets_schema_and_runtime — the P2-T04 no-secrets floor (schema + runtime)
    community_no_secrets_schema_and_runtime = bool(sandbox.community_tier_selftest()["no_secrets_tier"])

    # (4) perk_tier_flows_to_grant — a perk DECLARING `tier: community` → grant.sandbox_tier=community → catalog
    reg = tempfile.mkdtemp(prefix="tierwire-reg-")
    sd = os.path.join(reg, "mkt")
    os.makedirs(sd, exist_ok=True)
    json.dump({"perks": [{"id": "p1", "summary": "x", "tier": "community"}]},
              open(os.path.join(sd, "perks.json"), "w"))
    resolved = delegate.perk_sandbox_tier("mkt", "p1", reg)
    captured = {}

    def capture(_sock, req):
        captured["tier"] = grant_body(req["grant"]).get("sandbox_tier")
        raise RuntimeError("captured — short-circuit before exod runs")     # govd still minted the grant

    gk = Ed25519PrivateKey.generate()
    exo = Exod(Ed25519PrivateKey.generate(), grant_issuer_pub=gk.public_key())
    rec = {"run_id": "R", "skill": "mkt", "perk": "p1", "wrapper": "#!/bin/sh\n",
           "snippet_shas": {}, "credential_ids": [], "events": []}
    delegate.execute_step(rec, "1", "P", exod_socket="x", grant_key=gk, exod_pub=exo.public_key,
                          base=tempfile.mkdtemp(), request=capture, registry=reg, now=1000)
    cat = skill_index.catalog(reg)
    catalog_tier = next((p.get("tier") for s in cat["skills"] for p in s["perks"] if p["id"] == "p1"), "MISSING")
    perk_tier_flows_to_grant = bool(resolved == "community" and captured.get("tier") == "community"
                                    and catalog_tier == "community")

    checks = {"tier_maps": bool(pure["tier_maps"]), "monotone_floor": bool(pure["monotone_floor"]),
              "tier_enforced_at_grant": tier_enforced_at_grant,
              "community_no_secrets_schema_and_runtime": community_no_secrets_schema_and_runtime,
              "perk_tier_flows_to_grant": perk_tier_flows_to_grant}
    # bwrap_live/runsc_live are host facts (informational), NOT pass/fail gates — the wiring is proven on any host
    return {**checks, "bwrap_live": bool(pure["bwrap_live"]), "runsc_live": bool(pure["runsc_live"]),
            "ok": all(checks.values())}


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = tierwire_selftest()
    with open(os.path.join(store, "tierwire.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "tier_wire", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
