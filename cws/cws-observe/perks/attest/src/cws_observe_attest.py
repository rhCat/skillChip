#!/usr/bin/env python3
"""cws_observe_attest — record an ATTRIBUTED human testimony into a tamper-evident attest-ledger.

Some evidence cannot be manufactured by a governed run — an outsider completing a quickstart from public
docs, a human witnessing a milestone. This perk records such a claim as TESTIMONY, but never anonymously:
it demands ATTESTED_BY (who witnessed it) and appends a prev-hash-chained entry
`{seq, ts, claim, attested_by, grade, evidence_sha, prev}` to the attest-ledger, so a testimony is
ATTRIBUTED and tamper-evident (editing the claim or the attributor breaks the chain, which
cws-ledgercheck/verify reports). It records WHO said WHAT; it does NOT — cannot — verify the claim's truth.
That is the honest boundary of testimony (grade: testimony), distinct from redeem's governed-run evidence.

Reads from env: CLAIM (the statement), ATTESTED_BY (the attributor — required), GRADE (default
'testimony'), ATTEST_LEDGER (created if absent; default RECORD_STORE/attest-ledger.json), RECORD_STORE.
Exit 0 on a recorded attestation; nonzero if CLAIM or ATTESTED_BY is missing (an unattributed testimony is
refused, fail-closed).
"""
from __future__ import annotations
import hashlib
import json
import os
import sys
import time

# locate the cyberware repo root so we can import the shared, schema-aware ledger-digest helper
_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "govern"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "govern")):
    sys.path.insert(0, _root)

from infra.cwp import ledger  # noqa: E402


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "attest.json")
    os.makedirs(store, exist_ok=True)
    claim = (os.environ.get("CLAIM") or "").strip()
    attested_by = (os.environ.get("ATTESTED_BY") or "").strip()
    grade = (os.environ.get("GRADE") or "testimony").strip()
    ledger_path = os.environ.get("ATTEST_LEDGER") or os.path.join(store, "attest-ledger.json")

    def refuse(reason):
        json.dump({"tool": "cws_observe_attest", "verdict": "refused", "reason": reason}, open(out, "w"), indent=2)
        print(json.dumps({"tool": "cws_observe_attest", "verdict": "refused", "reason": reason, "report": out}))
        return 1

    if not claim:
        return refuse("CLAIM is required")
    if not attested_by:
        return refuse("ATTESTED_BY is required — a testimony is never anonymous (fail-closed)")

    if os.path.isfile(ledger_path):
        led = json.load(open(ledger_path))
    else:
        # a native testimony chain, ORIGIN-BOUND so cws-ledgercheck/verify (verify_chain) re-verifies it:
        # a testimony has no governed execution behind it, so it roots at generation-zero, the trust axiom.
        led = {"chain": "attest-ledger", "schema": ledger.CURRENT_MAJOR,
               "entries": [ledger.genesis("attest-ledger",
                           hashlib.sha256(b"cws-observe/attest:generation-zero").hexdigest())]}

    entries = led.setdefault("entries", [])
    schema = led.get("schema", ledger.CURRENT_MAJOR)
    # the testimony content is what is bound: tampering the claim, the attributor, or the grade breaks it
    evidence_sha = hashlib.sha256(f"{claim}\x00{attested_by}\x00{grade}".encode("utf-8")).hexdigest()
    record = {"ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
              "claim": claim, "attested_by": attested_by, "grade": grade, "evidence_sha": evidence_sha}
    entry = ledger.append(entries, record, schema)   # sets seq (genesis 0 -> 1..N) + prev-hash digest
    os.makedirs(os.path.dirname(os.path.abspath(ledger_path)), exist_ok=True)
    ledger.write_object_atomic(ledger_path, led)               # crash-atomic snapshot (dogfoods P1-T02)

    json.dump({"tool": "cws_observe_attest", "verdict": "recorded", "seq": entry["seq"],
               "claim": claim, "attested_by": attested_by, "grade": grade,
               "evidence_sha": evidence_sha, "attest_ledger": ledger_path}, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_observe_attest", "verdict": "recorded", "seq": entry["seq"],
                      "attested_by": attested_by, "grade": grade, "report": out}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
