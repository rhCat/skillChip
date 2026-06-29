#!/usr/bin/env python3
"""fleet_deploy — give a subagent a SCOPED GOVERNANCE DOMAIN, then register it to the fleet.

What this provides (and what it does NOT). The deploy spins the subagent its OWN govd, governing its
claims against a least-privilege chip + a per-actor ACL: in-scope claims get a blessed value-free plan,
out-of-scope claims are denied (`acl_skill_denied`). That bounds the subagent's GOVERNED surface — what it
can be blessed to do through the governed channel — so it cannot go rogue THROUGH that channel. It is the
per-subagent governance domain made concrete. It is NOT, by itself, an OS sandbox: a cooperative body
governs decisions while the subagent still executes steps client-side. For hard EXECUTION confinement, the
body must run delegated + exod (a stronger, separately-provisioned mode); this perk records the body's
`exec_mode`/`exod_attached` so the confinement status is explicit and auditable, never assumed.

The containment gates (fail-closed, BEFORE any `docker run`): the child must sit STRICTLY lower than its
parent on the fleet hierarchy, and its chip + ACL must be a CONTENT-IDENTICAL subset of the parent's —
every child skill must equal a parent skill by `skill_sha`, so a trojaned or foreign same-name skill
cannot ride along. Because this file's bytes are pinned by skill_sha (folded into chip_sha), the check is
tamper-evident: weakening it breaks verify_chip before govd will serve the skill.

Value-free: bearer/monitor tokens arrive only as *_FILE pointers; only their sha256 (the bearer) or a
0600 in-container file (the monitor token) is used — never a plaintext host argv, never the run-ledger.
"""
from __future__ import annotations
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import urllib.request


_FLEET_RANK = {"mothership": 1, "edge": 2, "subagent": 3}   # fleet HIERARCHY; lower = higher authority
                                                            # (mirrors infra.govern.fleetd._FLEET_RANK)
_NAME_RE = re.compile(r"^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,62}$")  # docker container-name charset (no arg injection)


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


def check_containment(parent_ft, child_ft, acl_leaves, parent_skills, child_skills):
    """The PURE, fail-closed containment decision (unit-tested independently of docker). Returns
    (ok, reason). parent_skills / child_skills are lists of {"leaf": <name>, "sha": <skill_sha>}; acl_leaves
    is a list of leaf names the child principal may invoke. Check order = reason precedence:
      1. both tiers must rank, and the child must be STRICTLY deeper than the parent (no upward/sideways);
      2. the requested ACL leaves must be a subset of the PARENT's leaves (can't grant what the parent lacks);
      3. EVERY child skill must equal a PARENT skill by CONTENT (skill_sha) — not by leaf name. This is the
         load-bearing gate: it defeats a trojaned same-leaf clone and a foreign-namespace skill, and it holds
         across the bare<->namespaced boundary (a verbatim compose copies the parent's skill_sha);
      4. the ACL leaves must be a subset of the CHILD's leaves (can't grant a skill the body doesn't carry)."""
    pr, cr = fleet_rank(parent_ft), fleet_rank(child_ft)
    if pr is None or cr is None:
        return (False, "fleet_tier_unknown")
    if not cr > pr:
        return (False, "fleet_tier_not_strictly_lower")
    parent_leaves = {s["leaf"] for s in parent_skills}
    parent_shas = {s["sha"] for s in parent_skills if s.get("sha")}
    child_leaves = {s["leaf"] for s in child_skills}
    acl = set(acl_leaves)
    if not acl <= parent_leaves:
        return (False, "acl_not_subset")
    if not (child_skills and all(s.get("sha") and s["sha"] in parent_shas for s in child_skills)):
        return (False, "chip_not_subset")        # every child skill must be a verbatim parent skill (by sha)
    if not acl <= child_leaves:
        return (False, "acl_exceeds_chip")
    return (True, None)


def _leaves(val):
    """A space/comma-separated env value -> a clean list of tokens (order preserved, blanks dropped)."""
    return [s for s in (val or "").replace(",", " ").split() if s]


def _chip_skills(chip_dir):
    """Each skill a chip declares in its root index.json manifest, as {"id": ns:name, "leaf": name,
    "sha": skill_sha}. No/!manifest -> [] (fail-closed: an unverifiable chip satisfies no subset check)."""
    idx = os.path.join(chip_dir, "index.json")
    if not os.path.isfile(idx):
        return []
    try:
        d = json.load(open(idx))
    except Exception:
        return []
    out = []
    for s in (d.get("skills") or []):
        sid = str(s.get("skill") or "")
        if sid:
            out.append({"id": sid, "leaf": sid.split(":")[-1], "sha": s.get("skill_sha")})
    return out


def _run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def _teardown(name, log):
    """stop + rm a container, then VERIFY it is actually gone (no fire-and-forget leak). Returns True iff
    removed; on a stubborn container, escalate to rm -f and re-check. Logged, never raises."""
    _run(["docker", "stop", name]); _run(["docker", "rm", name])
    if _run(["docker", "inspect", name]).returncode != 0:
        return True
    _run(["docker", "rm", "-f", name])                         # escalate once
    gone = _run(["docker", "inspect", name]).returncode != 0
    if log and not gone:
        log.write(f"WARNING: container {name} still present after stop+rm+rm-f\n")
    return gone


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
    # the parent chip defaults to the deploying node's OWN chip (least surprising + can't grant beyond it);
    # an explicit PARENT_CHIP_DIR is honored but, per metadata, MUST be the deployer's real chip (residual).
    parent_chip = os.path.expanduser(os.environ.get("PARENT_CHIP_DIR")
                                     or os.environ.get("CYBERWARE_SKILLCHIP") or "skillChip")
    acl_skills = _leaves(os.environ.get("ACL_SKILLS"))
    principal_id = os.environ.get("PRINCIPAL_ID") or "child-1"
    token_file = os.environ.get("TOKEN_FILE")
    monitor_token_file = os.environ.get("MONITOR_TOKEN_FILE")
    port = os.environ.get("PORT") or "5779"
    image = os.environ.get("IMAGE") or "cyberware-body:local"
    role = os.environ.get("ROLE") or "body"
    max_tier = os.environ.get("MAX_TIER") or None
    confine = (os.environ.get("CONFINE") or "").strip().lower() in ("1", "true", "yes")
    fleet_file = os.environ.get("FLEET_FILE") or "~/.cyberware/fleet.json"
    cwd = os.environ.get("CYBERWARE_ROOT") or os.getcwd()    # where `python3 -m infra.tool.*` resolves

    # ── required + well-formed inputs (validate before any value is used as a docker arg) ──
    if not _NAME_RE.match(node_name):
        return _refuse(out, "bad_node_name", node_name=node_name)
    if not str(port).isdigit():
        return _refuse(out, "bad_port", port=port)
    if not parent_chip or not os.path.isdir(parent_chip):
        return _refuse(out, "parent_chip_dir_required")
    if not token_file or not os.path.isfile(os.path.expanduser(token_file)):
        return _refuse(out, "token_file_required")

    parent_skills = _chip_skills(parent_chip)
    parent_leaves = {s["leaf"] for s in parent_skills}

    # ── cheap containment gates BEFORE building/spawning anything ──
    pr, cr = fleet_rank(parent_ft), fleet_rank(child_tier)
    if pr is None or cr is None:
        return _refuse(out, "fleet_tier_unknown", parent_fleet_tier=parent_ft, child_tier=child_tier)
    if not cr > pr:
        return _refuse(out, "fleet_tier_not_strictly_lower", parent_fleet_tier=parent_ft, child_tier=child_tier)
    if not set(acl_skills) <= parent_leaves:
        return _refuse(out, "acl_not_subset", acl=sorted(acl_skills), parent_skills=sorted(parent_leaves))

    # ── build / select the least-privilege child chip ──
    child_chip = os.path.join(store, "child-chip")
    if mode == "compose":
        sources = _leaves(os.environ.get("SKILLS"))
        if not sources:
            return _refuse(out, "skills_required_for_compose")
        # subset the PARENT chip down to EXACTLY the named skills (cartridge compile = least-privilege).
        # cartridge copies each skill verbatim FROM the parent, so the child's skill_sha == the parent's.
        r = _run([sys.executable, "-m", "infra.tool.cartridge", "--compile", *sources, "--out", child_chip],
                 cwd=cwd, env={**os.environ, "CYBERWARE_SKILLCHIP": parent_chip})
        log.write(r.stdout + r.stderr)
        if r.returncode != 0:
            return _refuse(out, "compose_failed", detail=(r.stderr or r.stdout).strip()[:400])
    elif mode == "mount":
        skill_dir = os.path.expanduser(os.environ.get("SKILL_DIR") or "")
        if not skill_dir or not os.path.isdir(skill_dir):
            return _refuse(out, "skill_dir_required_for_mount")
        # cartridge --verify checks the dir is INTERNALLY authentic; the parent-binding (every skill_sha is
        # the parent's) is enforced by check_containment below — a self-consistent foreign dir does NOT pass.
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

    child_skills = _chip_skills(child_chip)

    # ── AUTHORITATIVE containment re-check: content-identity subset against the REAL child chip ──
    ok, reason = check_containment(parent_ft, child_tier, acl_skills, parent_skills, child_skills)
    if not ok:
        return _refuse(out, reason, parent_fleet_tier=parent_ft, child_tier=child_tier,
                       child_skills=sorted(s["leaf"] for s in child_skills),
                       parent_skills=sorted(parent_leaves))

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

    # the monitor token NEVER goes on the host argv (ps/proc leak). Write it 0600 inside the mounted
    # ro rundir and read it container-side; the host docker argv carries only the cat command.
    mt_in = None
    if monitor_token_file and os.path.isfile(os.path.expanduser(monitor_token_file)):
        mtp = os.path.join(rundir, "monitor.token")
        with open(mtp, "w") as fh:
            fh.write(open(os.path.expanduser(monitor_token_file)).read().strip())
        os.chmod(mtp, 0o600)
        mt_in = "/etc/cyberware/monitor.token"

    # ── spin the body (entrypoint BYPASS via sh -c: the image entrypoint would mint agent-1 + clobber
    #    GOVD_PRINCIPALS; we honor the mounted scoped registry instead) ──
    _teardown(node_name, log)                                  # clear any stale container by this name
    govd = "python3 -m infra.govern.govd --config /etc/cyberware/govd.json --mode remote --port 5773"
    script = (f'GOVD_MONITOR_TOKEN="$(cat {mt_in})" exec {govd}' if mt_in else f'exec {govd}')
    docker_cmd = ["docker", "run", "-d", "--name", node_name,
                  "-p", f"127.0.0.1:{port}:5773",
                  "-v", f"{os.path.abspath(child_chip)}:/app/skillChip:ro",
                  "-v", f"{os.path.abspath(rundir)}:/etc/cyberware:ro",
                  "-e", "GOVD_CONFIG=/etc/cyberware/govd.json",
                  "-e", "GOVD_PRINCIPALS=/etc/cyberware/principals.json",
                  "-e", "CYBERWARE_SKILLCHIP=/app/skillChip", "-w", "/app",
                  "--entrypoint", "sh", image, "-c", script]
    r = _run(docker_cmd)
    log.write(r.stdout + r.stderr)
    if r.returncode != 0:
        _teardown(node_name, log)
        return _refuse(out, "docker_run_failed", detail=r.stderr.strip()[:400])

    # ── wait for /health; capture the body's exec_mode/exod_attached (confinement status, recorded) ──
    url = f"http://127.0.0.1:{port}"
    health, chip_sha, exec_mode, exod_attached = "down", None, None, None
    for _ in range(20):
        try:
            with urllib.request.urlopen(url + "/health", timeout=3) as resp:
                h = json.loads(resp.read())
            health, chip_sha = "ok", h.get("chip_sha")
            exec_mode, exod_attached = h.get("exec_mode"), h.get("exod_attached")
            break
        except Exception:
            time.sleep(2)
    if health != "ok":
        ok_gone = _teardown(node_name, log)
        return _refuse(out, "health_timeout", port=port,
                       note=("container stopped+removed; nothing registered" if ok_gone
                             else "WARNING: container may be leaked — stop+rm did not confirm removal"))
    # if the caller REQUIRES execution confinement, the body must come up delegated + exod-attached
    if confine and not (exec_mode == "delegated" and exod_attached):
        _teardown(node_name, log)
        return _refuse(out, "body_not_confined", exec_mode=exec_mode, exod_attached=exod_attached,
                       note="CONFINE was requested but the body is not delegated+exod; torn down")

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
           "exec_mode": exec_mode, "exod_attached": exod_attached, "confined": bool(exod_attached),
           "principal": principal_id, "acl_skills": acl_skills,
           "skills": sorted(s["leaf"] for s in child_skills),
           "health": "ok", "registered": registered, "dashboard": url + "/",
           "log": os.path.join(store, "deploy.log")}
    json.dump(rec, open(out, "w"), indent=2)
    print(json.dumps({"tool": "fleet_deploy", "status": "ok", "container": node_name,
                      "fleet_tier": child_tier, "url": url, "exec_mode": exec_mode,
                      "skills": sorted(s["leaf"] for s in child_skills)}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
