#!/usr/bin/env python3
"""fleet_deploy — spin a SCOPED, CONTAINED governed body for a subagent, then register it to the fleet.

The anti-rogue core. A confined body (exod) has no docker/host privilege, so a subagent can never
self-spawn a body — this perk is the ONLY path to one, and it enforces, fail-closed and BEFORE any
`docker run`, that the child sits at a STRICTLY-lower fleet_tier than its parent and that its chip + ACL
are a SUBSET of the parent's. Because this file's bytes are pinned by skill_sha (folded into chip_sha),
the containment check is tamper-evident: weakening it breaks verify_chip before govd will serve the skill.

Value-free: the bearer/monitor tokens arrive only as *_FILE pointers; only their sha256 (never the value)
lands in the registry, and nothing token-shaped reaches the run-ledger. govd governs the decision; the
operating agent's cooperative-mode porter runs docker; exod never receives docker.
"""
from __future__ import annotations
import hashlib
import json
import os
import subprocess
import sys
import time
import urllib.request


_FLEET_RANK = {"mothership": 1, "edge": 2, "subagent": 3}   # fleet HIERARCHY; lower = higher authority
                                                            # (mirrors infra.govern.fleetd._FLEET_RANK)


def fleet_rank(ft):
    """Rank on the fleet hierarchy: a named tier via _FLEET_RANK, or a bare positive int ('and so on'
    beyond subagent); anything else -> None (unranked, never elevated)."""
    if ft is None or isinstance(ft, bool):
        return None
    if isinstance(ft, int):
        return ft if ft > 0 else None
    s = str(ft).strip().lower()
    if s in _FLEET_RANK:
        return _FLEET_RANK[s]
    return int(s) if (s.isdigit() and int(s) > 0) else None


def check_containment(parent_ft, child_ft, acl_skills, parent_set, child_set):
    """The PURE, fail-closed containment decision (unit-tested independently of docker). Returns
    (ok, reason). The *_set args are sets of skill leaves. Check order = reason precedence:
      1. both tiers must rank, and the child must be STRICTLY deeper than the parent (no upward/sideways);
      2. the requested ACL must be a subset of the PARENT's catalog (can't grant what the parent lacks);
      3. the CHILD chip must be a subset of the parent's catalog (compose/mount can't smuggle extra skills);
      4. the ACL must be a subset of the CHILD chip (can't grant a skill the body doesn't even carry)."""
    pr, cr = fleet_rank(parent_ft), fleet_rank(child_ft)
    if pr is None or cr is None:
        return (False, "fleet_tier_unknown")
    if not cr > pr:
        return (False, "fleet_tier_not_strictly_lower")
    acl, parent, child = set(acl_skills), set(parent_set), set(child_set)
    if not acl <= parent:
        return (False, "acl_not_subset")
    if not child <= parent:
        return (False, "chip_not_subset")
    if not acl <= child:
        return (False, "acl_exceeds_chip")
    return (True, None)


def _leaves(val):
    """A space/comma-separated env value -> a clean list of tokens (order preserved, blanks dropped)."""
    return [s for s in (val or "").replace(",", " ").split() if s]


def _chip_leaves(chip_dir):
    """The set of skill leaves a chip offers, from its root index.json manifest. No/!manifest -> empty set
    (fail-closed: an unverifiable chip satisfies no subset check)."""
    idx = os.path.join(chip_dir, "index.json")
    if not os.path.isfile(idx):
        return set()
    try:
        d = json.load(open(idx))
    except Exception:
        return set()
    out = set()
    for s in (d.get("skills") or []):
        sid = str(s.get("skill") or "")
        leaf = sid.split(":")[-1] if ":" in sid else sid
        if leaf:
            out.add(leaf)
    return out


def _run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def _refuse(out, reason, **detail):
    """Fail-closed: record a value-free refusal and exit non-zero. NOTHING was spawned/registered."""
    json.dump({"tool": "fleet_deploy", "status": "refused", "reason": reason, **detail},
              open(out, "w"), indent=2)
    print(json.dumps({"tool": "fleet_deploy", "status": "refused", "reason": reason}))
    return 2


def _register(fleet_file, row):
    """Append/replace a roster row by name, atomically. Creates {nodes:[]} if absent. CONFIG write only
    (the operator's private ~/.cyberware roster — never the repo)."""
    fleet_file = os.path.expanduser(fleet_file)
    parent = os.path.dirname(fleet_file)
    if parent:
        os.makedirs(parent, exist_ok=True)
    data = {"nodes": []}
    if os.path.isfile(fleet_file):
        try:
            data = json.load(open(fleet_file))
        except Exception:
            data = {"nodes": []}
    nodes = [n for n in (data.get("nodes") or []) if n.get("name") != row["name"]]
    nodes.append({k: v for k, v in row.items() if v is not None})
    data["nodes"] = nodes
    tmp = fleet_file + ".tmp"
    json.dump(data, open(tmp, "w"), indent=2)
    os.replace(tmp, fleet_file)


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "deploy.json")
    log = open(os.path.join(store, "deploy.log"), "w")

    mode = (os.environ.get("MODE") or "compose").strip().lower()
    node_name = os.environ.get("NODE_NAME") or ""
    child_tier = os.environ.get("CHILD_TIER")
    parent_ft = os.environ.get("PARENT_FLEET_TIER")
    parent_chip = os.path.expanduser(os.environ.get("PARENT_CHIP_DIR") or "")
    acl_skills = _leaves(os.environ.get("ACL_SKILLS"))
    principal_id = os.environ.get("PRINCIPAL_ID") or "child-1"
    token_file = os.environ.get("TOKEN_FILE")
    monitor_token_file = os.environ.get("MONITOR_TOKEN_FILE")
    port = os.environ.get("PORT") or "5779"
    image = os.environ.get("IMAGE") or "cyberware-body:local"
    role = os.environ.get("ROLE") or "body"
    max_tier = os.environ.get("MAX_TIER") or None
    fleet_file = os.environ.get("FLEET_FILE") or "~/.cyberware/fleet.json"
    cwd = os.environ.get("CYBERWARE_ROOT") or os.getcwd()    # where `python3 -m infra.tool.*` resolves

    # ── required inputs ──
    if not node_name:
        return _refuse(out, "node_name_required")
    if not parent_chip or not os.path.isdir(parent_chip):
        return _refuse(out, "parent_chip_dir_required")
    if not token_file or not os.path.isfile(os.path.expanduser(token_file)):
        return _refuse(out, "token_file_required")

    parent_set = _chip_leaves(parent_chip)

    # ── cheap containment gates BEFORE building/spawning anything ──
    pr, cr = fleet_rank(parent_ft), fleet_rank(child_tier)
    if pr is None or cr is None:
        return _refuse(out, "fleet_tier_unknown", parent_fleet_tier=parent_ft, child_tier=child_tier)
    if not cr > pr:
        return _refuse(out, "fleet_tier_not_strictly_lower", parent_fleet_tier=parent_ft, child_tier=child_tier)
    if not set(acl_skills) <= parent_set:
        return _refuse(out, "acl_not_subset", acl=sorted(acl_skills), parent_skills=sorted(parent_set))

    # ── build / select the least-privilege child chip ──
    child_chip = os.path.join(store, "child-chip")
    if mode == "compose":
        sources = _leaves(os.environ.get("SKILLS"))
        if not sources:
            return _refuse(out, "skills_required_for_compose")
        # subset the PARENT chip down to EXACTLY the named skills (cartridge compile = least-privilege).
        # A skill not present in the parent, or an unauthentic source, makes cartridge raise -> non-zero.
        r = _run([sys.executable, "-m", "infra.tool.cartridge", "--compile", *sources, "--out", child_chip],
                 cwd=cwd, env={**os.environ, "CYBERWARE_SKILLCHIP": parent_chip})
        log.write(r.stdout + r.stderr)
        if r.returncode != 0:
            return _refuse(out, "compose_failed", detail=(r.stderr or r.stdout).strip()[:400])
    elif mode == "mount":
        skill_dir = os.path.expanduser(os.environ.get("SKILL_DIR") or "")
        if not skill_dir or not os.path.isdir(skill_dir):
            return _refuse(out, "skill_dir_required_for_mount")
        # cartridge --verify exits 0 regardless and reports {ok}; trust the dir only when ok is true.
        v = _run([sys.executable, "-m", "infra.tool.cartridge", "--verify", skill_dir], cwd=cwd)
        log.write(v.stdout + v.stderr)
        try:
            verdict = json.loads(v.stdout or "{}")
        except Exception:
            verdict = {}
        if v.returncode != 0 or not verdict.get("ok"):
            return _refuse(out, "mount_unauthentic", detail=(v.stdout + v.stderr).strip()[:400])
        child_chip = skill_dir
    else:
        return _refuse(out, "bad_mode", mode=mode)

    child_set = _chip_leaves(child_chip)

    # ── AUTHORITATIVE containment re-check against the REAL child chip ──
    ok, reason = check_containment(parent_ft, child_tier, acl_skills, parent_set, child_set)
    if not ok:
        return _refuse(out, reason, parent_fleet_tier=parent_ft, child_tier=child_tier,
                       child_skills=sorted(child_set), parent_skills=sorted(parent_set))

    # ── mint the scoped principal registry (WRAPPED format; only the token's sha is persisted) ──
    tok_sha = hashlib.sha256(open(os.path.expanduser(token_file)).read().strip().encode()).hexdigest()
    acl = {"skills": acl_skills}
    if max_tier:
        acl["max_tier"] = max_tier
    rundir = os.path.join(store, "run")
    os.makedirs(rundir, exist_ok=True)
    json.dump({"principals": {principal_id: {"token_sha": tok_sha, "rate": 30, "burst": 60, "acl": acl}}},
              open(os.path.join(rundir, "principals.json"), "w"), indent=2)
    json.dump({"mode": "remote"}, open(os.path.join(rundir, "govd.json"), "w"), indent=2)
    monitor_token = ""
    if monitor_token_file and os.path.isfile(os.path.expanduser(monitor_token_file)):
        monitor_token = open(os.path.expanduser(monitor_token_file)).read().strip()

    # ── spin the body (entrypoint BYPASS: the image entrypoint would mint agent-1 + clobber GOVD_PRINCIPALS) ──
    _run(["docker", "stop", node_name]); _run(["docker", "rm", node_name])   # clear any stale container (no -f: oversight-clean)
    docker_cmd = ["docker", "run", "-d", "--name", node_name,
                  "-p", f"127.0.0.1:{port}:5773",
                  "-v", f"{os.path.abspath(child_chip)}:/app/skillChip:ro",
                  "-v", f"{os.path.abspath(rundir)}:/etc/cyberware:ro",
                  "-e", "GOVD_CONFIG=/etc/cyberware/govd.json",
                  "-e", "GOVD_PRINCIPALS=/etc/cyberware/principals.json",
                  "-e", "CYBERWARE_SKILLCHIP=/app/skillChip", "-w", "/app"]
    if monitor_token:
        docker_cmd += ["-e", f"GOVD_MONITOR_TOKEN={monitor_token}"]
    docker_cmd += ["--entrypoint", "python3", image, "-m", "infra.govern.govd",
                   "--config", "/etc/cyberware/govd.json", "--mode", "remote", "--port", "5773"]
    r = _run(docker_cmd)
    log.write(r.stdout + r.stderr)
    if r.returncode != 0:
        _run(["docker", "stop", node_name]); _run(["docker", "rm", node_name])
        return _refuse(out, "docker_run_failed", detail=r.stderr.strip()[:400])

    # ── wait for /health; on timeout, tear down — no ghost row ──
    url = f"http://127.0.0.1:{port}"
    health, chip_sha = "down", None
    for _ in range(20):
        try:
            with urllib.request.urlopen(url + "/health", timeout=3) as resp:
                health, chip_sha = "ok", json.loads(resp.read()).get("chip_sha")
                break
        except Exception:
            time.sleep(2)
    if health != "ok":
        _run(["docker", "stop", node_name]); _run(["docker", "rm", node_name])
        return _refuse(out, "health_timeout", note="container stopped+removed; nothing registered", port=port)

    # ── register to the roster (config write, atomic) ──
    registered = True
    try:
        _register(fleet_file, {"name": node_name, "role": role, "fleet_tier": child_tier,
                               "tier": max_tier, "url": url, "chip_sha": chip_sha,
                               "token_file": monitor_token_file})
    except Exception as e:                                   # a read-only roster path must not orphan a live body
        registered = False
        log.write(f"register failed: {e}\n")

    rec = {"tool": "fleet_deploy", "status": "ok", "container": node_name, "fleet_tier": child_tier,
           "parent_fleet_tier": parent_ft, "port": int(port), "url": url, "chip_sha": chip_sha,
           "principal": principal_id, "acl_skills": acl_skills, "skills": sorted(child_set),
           "health": "ok", "registered": registered, "dashboard": url + "/",
           "log": os.path.join(store, "deploy.log")}
    json.dump(rec, open(out, "w"), indent=2)
    print(json.dumps({"tool": "fleet_deploy", "status": "ok", "container": node_name,
                      "fleet_tier": child_tier, "url": url, "skills": sorted(child_set)}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
