#!/usr/bin/env python3
"""cws_crosslang — diff the independent Go verifier against canonical.py + sign.py over the corpus (P0-T08).

The external anchor (meta-rule M3) made into a governed verdict: builds verifiers/go, runs it over CORPUS
(canonical bytes + digests) and SIG_CORPUS (DSSE/Ed25519 sig verdicts), and asserts the Go implementation
reproduces the Python one byte-for-byte / verdict-for-verdict. A single divergence fails the gate — that
is the point of a second, independently-written implementation. Requires the `go` toolchain.

Reads CORPUS (+ optional SIG_CORPUS), RECORD_STORE from env.
"""
from __future__ import annotations
import base64
import json
import os
import subprocess
import sys
import tempfile

_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "govern"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "govern")):
    sys.path.insert(0, _root)

from infra.cwp import canonical  # noqa: E402


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "crosslang.json")
    os.makedirs(store, exist_ok=True)
    go_dir = os.path.join(_root, "verifiers", "go")
    corpus_path = os.environ["CORPUS"]
    sig_path = os.environ.get("SIG_CORPUS")

    binp = os.path.join(tempfile.mkdtemp(prefix="jcs-"), "jcs")
    b = subprocess.run(["go", "build", "-o", binp, "."], cwd=go_dir, capture_output=True, text=True)
    if b.returncode != 0:
        json.dump({"status": "fail", "err": "go build failed", "detail": b.stderr[-400:]}, open(out, "w"), indent=2)
        print(json.dumps({"tool": "cws_crosslang", "status": "fail", "reason": "go_build", "report": out}))
        return 1

    corpus = json.load(open(corpus_path))
    go_canon = {r["name"]: r for r in json.loads(
        subprocess.run([binp], stdin=open(corpus_path), capture_output=True, text=True).stdout)}
    diffs = []
    for vec in corpus:
        n = vec["name"]
        if go_canon[n]["canonical"] != canonical.canonicalize(vec["input"]):
            diffs.append(f"{n}: canonical")
        elif go_canon[n]["digest"] != canonical.digest(vec["input"]):
            diffs.append(f"{n}: digest")

    sig_total = 0
    if sig_path and os.path.isfile(sig_path):
        from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
        from infra.cwp import sign
        sigs = json.load(open(sig_path))
        sig_total = len(sigs)
        go_sig = {r["name"]: r["valid"] for r in json.loads(
            subprocess.run([binp, "sig"], stdin=open(sig_path), capture_output=True, text=True).stdout)}
        for v in sigs:
            pub = Ed25519PublicKey.from_public_bytes(base64.b64decode(v["pubkey"]))
            py = sign.verify(v["envelope"], pub)
            if go_sig[v["name"]] != py or py != v["expect_valid"]:
                diffs.append(f"{v['name']}: sig verdict")

    total = len(corpus) + sig_total
    ok = not diffs
    report = {"status": "ok" if ok else "fail", "total": total, "canonical_vectors": len(corpus),
              "sig_vectors": sig_total, "match": ok, "diffs": diffs[:20]}
    json.dump(report, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_crosslang", "status": report["status"], "total": total,
                      "diffs": len(diffs), "report": out}))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
