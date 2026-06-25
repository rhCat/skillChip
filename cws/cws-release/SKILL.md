---
skill: cws-release
name: Release transparency
perks: [sign, transparency, engine, publish, revoke, manifestlint, approval, tierwire, inflight, feedtiers, keyrotate, receipts, timeanchor, citrinitas, security-doorbell]
---

# cws-release — Release transparency (V-EXT, the M4 / SV-4 layer)

The SV-4 promise: *skills and the engine are signed, publicly logged, and revocable; what runs is the
published artifact and nothing else.* This skill gates the release pipeline.

## Perks
| perk | task | what |
|---|---|---|
| `sign` | P3-T01 | **publisher signing** — the chip release manifest (`chip_sha` + per-skill `skill_sha`) is signed with the publisher Ed25519ph key (cosign-shaped) and verified against a **pinned TUF root** (`spec/tuf/publisher-root.pub`). An unsigned or tampered release is refused at all three entry points — **chipfetch · govd boot · exod run** (the tri-layer refusal). Exit 0 iff the signed release passes + unsigned/tampered are refused + the root is pinned. |
| `transparency` | P3-T02 | **offline transparency** — every release becomes a leaf in a Merkle log whose head is a **publisher-signed tree head** (Ed25519ph). A release ships a self-contained **inclusion proof**; a verifier recomputes the Merkle root from leaf + audit path and checks the signed head against the **pinned root** — **no live Rekor is contacted**. An unsigned/forged head, a tampered leaf, or a wrong index all fail offline. Shares the audited Merkle primitive with Ledger-v2 checkpoints. |
| `engine` | P3-T05 | **engine attestation + mutual handshake** — the engine's reproducible-build (P0-T13) digest is publisher-signed; before two principals run together they **mutually attest** each other's live binary, and a **one-byte tamper on either side** re-measures differently, yielding **engine_unattested** (fails closed). A dual-signed **release receipt** binds chip release + engine so the live engine's health matches the signed release. |
| `publish` | P3-T15 | **governed release receipt** — composes the three legs into ONE dual-signed (chip + engine), transparency-logged receipt and verifies it end to end **offline** under the pinned root. The inclusion proof is stored (`rekor_proof_stored`), and tampering **any** single leg — chip release, live engine, or transparency head — fails the receipt closed. |

The cores are `infra/cwp/{release,translog,engineattest,publish}.py`; each perk's hermetic self-test signs
with an ephemeral key so it runs in CI (needs only openssl/ed25519ph), while a real release uses the committed
pinned root + the publisher's offline key.
| `revoke` | P3-T03 | **signed revocation feed** — a monotonic, publisher-signed `{seq, expires, revoked[]}` names what must no longer run. A revoked artifact is refused; a feed older than `max_age` is **`feed_stale`** and **fails closed** (a consumer that cannot refresh stops trusting it — this bounds revocation latency); a replayed older feed is **`rollback`**; a forged feed is **`bad_signature`**. |
| `manifestlint` | P3-T10 | **publish-time manifest lint** — what a perk actually does must match what it declares. Extracts the binaries its porter scripts invoke, the egress they reach, and the capabilities it grants, and refuses to publish on any drift: **undeclared binary**, **undeclared egress**, or **capability mismatch** — catching 100% of these (how a benign-looking skill smuggles a binary, a callback host, or a writable path). |
| `approval` | P3-T04 | **WebAuthn approval for destructive grants** — the challenge is `sha256(JCS(doc))`, binding a hardware approval to one canonical doc; verified **fully offline** from the stored assertion + COSE key (no live authenticator). A different doc, a flipped signature, a cleared User-Verified bit, or a wrong origin are each refused, and a destructive grant without a verified approval does not proceed. |
| `tierwire` | P3-T11 | **tier wiring to P2 sandbox profiles** — a grant's `sandbox_tier` (the perk's catalog tier) selects the confinement **backend**: `community` (untrusted marketplace) demands the **gVisor/runsc** box, `core`/`verified` run in **bwrap**. The operator `--backend` is a **floor** the tier may only ratchet **up** (community forces runsc even under a bwrap floor; a core grant on a runsc-floored host is **never** downgraded), and a required backend that can't enforce on the host **refuses (fail-closed)**. The tier flows `perks.json → govd → grant → discovery catalog`, and the **community no-secrets floor** holds at schema + runtime. Enforced at the grant in `exod.run_step`. |
| `inflight` | P3-T13 | **revocation-in-flight** — the in-flight runner consults the signed feed at each step boundary; an ordinary revocation lets the in-progress step finish then refuses the next (boundary halt), a **critical** revocation aborts the in-progress step immediately (one step sooner). |
| `feedtiers` | P3-T12 | **feed availability tiers + grace** — through a feed outage, read-only proceeds to **grace-2** while **destructive refuses**; past grace-2 everything fails closed; a forged feed refuses at every tier; presenting a fresh feed re-converges with no ledger surgery. |
| `keyrotate` | P3-T06 | **key-rotation drill** — a **cross-signed** rotation record (old + new keys); during the overlap a grant from either key verifies; once the old key is revoked an old-key grant is refused while the new key still works. |
| `receipts` | P3-T14 | **finalized receipts** — two independent **Ed25519-DSSE** signatures over one **in-toto** statement; a single signature, a tampered statement, or two signatures from one key do not pass as finalized. |
| `timeanchor` | P3-T07 | **TSA time anchors** — a high-value receipt is settlement-eligible only with a TSA token that **verifies offline** against the receipt digest; absence, a tampered token, or a token bound to a different receipt block settlement. |
| `citrinitas` | P3-T09 | **Citrinitas publish gate** — verified-tier admission requires the [`alchemy`](../../general/alchemy/SKILL.md) verbs (extract + conserve + classify + concord). A seeded **conservation defect**, **unnamed shape**, or **CFG mismatch** each **blocks** publish with its named reason, and **chip-wide concord** passes for every modeled porter. |

## Status — M4 / SV-4 closed
The Citrinitas publish gate (P3-T09) gates verified-tier admission on the
[`alchemy`](../../general/alchemy/SKILL.md) validator (concordance, P3-T08), which is built — closing
**M4 / SV-4** end to end.
