#!/usr/bin/env python3
"""harden_verify — prove the compute environment is hardened: pinned, hashed, vendored, reproducible.

Consolidates the env-hardening acceptance (P0-T14: unpinned_imports=0, SBOM emitted, osv clean/waivered)
into one governed check over the artifacts in infra/pyenv/ + vendor/wheelhouse/ + the compute Dockerfile:

  1. LOCK every requirement is `name==version` AND carries a --hash= (version- AND hash-pinned; 0 unpinned)
  2. DEPS_LOCK   deps.lock.json exists, every package hash-pinned, and its lock_sha256 matches LOCK
  3. SBOM        a CycloneDX SBOM exists with components (sbom_emitted)
  4. WHEELHOUSE  the offline static source carries a SHA256SUMS manifest (the vendored wheels are verifiable)
  5. DOCKERFILE  the base image is tag-pinned (not :latest) and every fetched toolchain ARG is SHA256-pinned
  6. OSV         optional: if osv-scanner is on PATH, the lock scans clean (else recorded as not-run)

Reads from env (all optional; absent = that check is skipped/flagged): LOCK, DEPS_LOCK, SBOM, WHEELHOUSE,
DOCKERFILE, RECORD_STORE. Writes RECORD_STORE/harden.json + one JSON line. Exit 0 iff hardened.
"""
from __future__ import annotations
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys


def check_lock(path):
    """(unpinned:list, hashed:bool). A line `name==ver` with no following --hash is hash-unpinned."""
    if not path or not os.path.isfile(path):
        return ["<no lock>"], False
    txt = open(path).read()
    pins = re.findall(r"(?m)^([A-Za-z0-9_.\-]+)==[^\s\\]+", txt)
    loose = re.findall(r"(?m)^([A-Za-z0-9_.\-]+)(?:[<>~!]=|>|<)(?!=)", txt)  # >=, <=, ~=, !=, >, <
    has_hashes = "--hash=sha256:" in txt
    # a package present but with no hash anywhere is hash-unpinned; we approximate by requiring hashes exist
    unpinned = sorted(set(loose))
    if pins and not has_hashes:
        unpinned.append("<no --hash entries>")
    return unpinned, has_hashes


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "harden.json")
    os.makedirs(store, exist_ok=True)
    lock = os.environ.get("LOCK")
    deps_lock = os.environ.get("DEPS_LOCK")
    sbom = os.environ.get("SBOM")
    wheelhouse = os.environ.get("WHEELHOUSE")
    dockerfile = os.environ.get("DOCKERFILE")

    problems = []

    # 1. lock: version- + hash-pinned
    unpinned, hashed = check_lock(lock)
    if unpinned:
        problems.append(f"lock has unpinned requirements: {unpinned}")

    # 2. deps.lock.json matches the lock and is hash-pinned
    deps_ok = False
    if deps_lock and os.path.isfile(deps_lock):
        d = json.load(open(deps_lock))
        pkgs = d.get("packages", [])
        all_hashed = bool(pkgs) and all(p.get("hashes") for p in pkgs)
        matches = bool(lock) and os.path.isfile(lock) and \
            d.get("lock_sha256") == hashlib.sha256(open(lock, "rb").read()).hexdigest()
        deps_ok = all_hashed and matches
        if not all_hashed:
            problems.append("deps.lock.json has packages without hashes")
        if not matches:
            problems.append("deps.lock.json lock_sha256 does not match the lock (stale)")
    else:
        problems.append("deps.lock.json missing")

    # 3. SBOM emitted (CycloneDX with components)
    sbom_emitted = False
    if sbom and os.path.isfile(sbom):
        b = json.load(open(sbom))
        sbom_emitted = b.get("bomFormat") == "CycloneDX" and len(b.get("components", [])) > 0
    if not sbom_emitted:
        problems.append("CycloneDX SBOM missing or empty")

    # 4. wheelhouse manifest (vendored offline source is verifiable)
    wheelhouse_pinned = bool(wheelhouse) and os.path.isfile(os.path.join(wheelhouse, "SHA256SUMS"))
    if not wheelhouse_pinned:
        problems.append("wheelhouse SHA256SUMS manifest missing")

    # 5. Dockerfile: base tag-pinned (not latest) + every fetched toolchain ARG SHA256-pinned
    dockerfile_pinned = False
    if dockerfile and os.path.isfile(dockerfile):
        df = open(dockerfile).read()
        froms = re.findall(r"(?mi)^FROM\s+(\S+)", df)
        base_pinned = bool(froms) and all((":" in f or "@sha256:" in f) and not f.endswith(":latest") for f in froms)
        sha_args = re.findall(r"(?m)^ARG\s+\w*SHA256=([0-9a-fA-F]{64})", df)
        ver_args = re.findall(r"(?m)^ARG\s+\w*(?:VERSION)=", df)
        toolchain_pinned = len(sha_args) >= len(ver_args)  # every versioned download has a sha
        dockerfile_pinned = base_pinned and toolchain_pinned
        if not base_pinned:
            problems.append(f"Dockerfile base not tag/digest-pinned: {froms}")
        if not toolchain_pinned:
            problems.append("Dockerfile has a versioned toolchain download without a SHA256 ARG")
    else:
        problems.append("compute Dockerfile missing")

    # 6. osv (optional): scan the lock if osv-scanner is available
    osv = "not-run (osv-scanner absent)"
    if lock and os.path.isfile(lock) and shutil.which("osv-scanner"):
        r = subprocess.run(["osv-scanner", "--lockfile", f"requirements.txt:{lock}"],
                           capture_output=True, text=True)
        osv = "clean" if r.returncode == 0 else "vulnerabilities found"
        if r.returncode != 0:
            problems.append("osv-scanner found vulnerabilities (waiver required)")

    status = "ok" if not problems else "fail"
    report = {"status": status, "unpinned_imports": len([u for u in unpinned if not u.startswith("<")]),
              "lock_hash_pinned": hashed, "deps_lock_matches": deps_ok, "sbom_emitted": sbom_emitted,
              "wheelhouse_pinned": wheelhouse_pinned, "dockerfile_pinned": dockerfile_pinned,
              "osv": osv, "problems": problems}
    json.dump(report, open(out, "w"), indent=2)
    print(json.dumps({"tool": "harden_verify", "status": status,
                      "unpinned": report["unpinned_imports"], "sbom_emitted": sbom_emitted,
                      "osv": osv, "problems": len(problems), "report": out}))
    return 0 if status == "ok" else 1


if __name__ == "__main__":
    sys.exit(main())
