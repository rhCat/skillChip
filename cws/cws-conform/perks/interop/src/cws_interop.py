#!/usr/bin/env python3
"""cws_interop — prove cwp <-> cosign/sigstore DSSE interop at the Ed25519ph layer (P0-T03).

cosign/sigstore sign DSSE attestations with Ed25519ph (HashEdDSA over SHA-512 of the PAE), NOT pure
Ed25519. cwp's native signatures stay pure Ed25519; infra/cwp/cosign.py bridges the ph gap via OpenSSL.
This gate proves BOTH directions of the interop acceptance:

  A. cosign-generated DSSE verifies in cwp — cwp.verify_ph accepts a REAL cosign attest-blob envelope
     (vendored fixture) and rejects a tampered one.
  B. cwp-produced DSSE verifies under cosign's engine — cwp.sign_ph (Ed25519ph) over a fresh key yields an
     envelope the Go anchor (jcs `phsig` = crypto/ed25519.VerifyWithOptions{SHA512}, cosign's OWN
     primitive) verifies.

The Go anchor is the faithful oracle for direction B because cosign's CLI `verify-blob-attestation --key`
cannot verify a key-based ed25519ph attestation — it fails on cosign's OWN output (an upstream cosign
limitation, recorded). Reads COSIGN_ENVELOPE, COSIGN_PUB, RECORD_STORE from env. Requires openssl(>=3.4)
+ go. Writes RECORD_STORE/interop.json + one JSON line; exit 0 iff both directions hold.
"""
from __future__ import annotations
import base64
import json
import os
import subprocess
import sys
import tempfile

# ascend to the cyberware root so we can import infra.cwp + build verifiers/go (the cosign-engine oracle)
_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "govern"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "govern")):
    sys.path.insert(0, _root)

from cryptography.hazmat.primitives import serialization  # noqa: E402

from infra.cwp import canonical, cosign  # noqa: E402


def _go_phsig_valid(pub_raw_b64, envelope):
    """Verify a DSSE envelope under the Go anchor's ed25519ph mode (cosign's verification primitive)."""
    go_dir = os.path.join(_root, "verifiers", "go")
    binp = os.path.join(tempfile.mkdtemp(prefix="jcs-"), "jcs")
    b = subprocess.run(["go", "build", "-o", binp, "."], cwd=go_dir, capture_output=True, text=True)
    if b.returncode != 0:
        raise RuntimeError(f"go build failed: {b.stderr[-300:]}")
    vec = [{"name": "cwp_ph", "pubkey": pub_raw_b64, "envelope": envelope}]
    r = subprocess.run([binp, "phsig"], input=json.dumps(vec), capture_output=True, text=True)
    return bool(json.loads(r.stdout)[0]["valid"])


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "interop.json")
    os.makedirs(store, exist_ok=True)
    cosign_env = json.load(open(os.environ["COSIGN_ENVELOPE"]))
    cosign_pub = os.environ["COSIGN_PUB"]

    # Direction A — cwp verifies REAL cosign output, and rejects a tampered payload.
    a_accept = cosign.verify_ph(cosign_env, cosign_pub)
    tampered = dict(cosign_env)
    tampered["payload"] = base64.b64encode(base64.b64decode(cosign_env["payload"]) + b" ").decode()
    a_reject = not cosign.verify_ph(tampered, cosign_pub)

    # Direction B — cwp ph-signs; cosign's engine (Go ed25519ph) verifies it.
    d = tempfile.mkdtemp(prefix="interop-")
    priv, pub = os.path.join(d, "k.pem"), os.path.join(d, "k.pub")
    subprocess.run(["openssl", "genpkey", "-algorithm", "ed25519", "-out", priv], capture_output=True, text=True)
    subprocess.run(["openssl", "pkey", "-in", priv, "-pubout", "-out", pub], capture_output=True, text=True)
    env = cosign.sign_ph(canonical.canonical_bytes({"interop": "cwp->cosign", "n": 1}), priv)
    pub_raw = serialization.load_pem_public_key(open(pub, "rb").read()).public_bytes(
        serialization.Encoding.Raw, serialization.PublicFormat.Raw)
    b_verify = _go_phsig_valid(base64.b64encode(pub_raw).decode(), env)

    ok = a_accept and a_reject and b_verify
    report = {"status": "ok" if ok else "fail",
              "cosign_to_cwp": {"accepts_real_cosign": a_accept, "rejects_tamper": a_reject},
              "cwp_to_cosign_engine": {"go_ed25519ph_verifies": b_verify},
              "note": ("cosign signs DSSE with Ed25519ph; cwp native is pure Ed25519, bridged via OpenSSL "
                       "(infra/cwp/cosign.py). cosign CLI verify-blob-attestation --key cannot verify a "
                       "key-based ph attestation (fails on its own output), so the Go anchor — cosign's own "
                       "ed25519.VerifyWithOptions engine — is the oracle for direction B.")}
    json.dump(report, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_interop", "status": report["status"],
                      "cosign_to_cwp": a_accept and a_reject, "cwp_to_cosign": b_verify, "report": out}))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
