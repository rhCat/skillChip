---
skill: cws-release
name: Release transparency
perks: [sign, transparency, engine, publish]
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

## Coming (the rest of the M4 cone)
The Citrinitas publish gate (P3-T09) depends on the `alchemy` validator (concordance, P3-T08), which is not
built yet — that validator is the remaining gate before M4 / SV-4 fully closes.
