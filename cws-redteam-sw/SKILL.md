---
skill: cws-redteam-sw
name: Software-tier red-team corpus
perks: [rt-tamper-script, rt-snippet-toctou, rt-ledger-tamper, rt-grant-replay, rt-grant-expired, rt-grant-forged]
---

# cws-redteam-sw — Software-tier red-team corpus (SV-1 / SV-2)

An adversarial **expected-refusal** corpus against the boundaries cyberware enforces *today in software*:
the executor's tamper + per-step snippet gates and the Ledger-v2 chain verifier. Each perk MOUNTS a real
attack in a throwaway sandbox and asserts the boundary **refuses** it (a recorded refusal is evidence —
meta-rule M4), with an **oracle**: a clean control must be accepted, so a perk goes RED the moment its gate
goes silently no-op. The pass is *"the boundary held — it failed the attack on purpose under observation."*

> **Honest scope — this is the SOFTWARE tier, NOT the SV-3 kernel gate.** SV-3 ("execution becomes a
> *kernel*-enforced boundary") demands the ≥12-behavior corpus refuse with the software scan DISABLED, over
> an `exod` daemon + sandbox (bwrap/seccomp/cgroups) that **does not exist in the repo yet**. That skill is
> the kernel `cws-redteam` (P2-T08), redeemable only after the `exod` subject is built. `cws-redteam-sw`
> is named distinctly and **redeems nothing in the P2 cone** — every P2 task is `validated_by: cws-redteam`,
> so a same-named pass would falsely close M3 against a boundary that isn't there. This is the legitimate
> precursor that extends into the kernel corpus once `exod` lands.

## Perks
| perk | tool | attack → boundary that must refuse |
|---|---|---|
| `rt-tamper-script` | `rt_tamper_script` | edit a compiled script after the snapshot → executor tamper check (exit 4) |
| `rt-snippet-toctou` | `rt_snippet_toctou` | mutate a perk porter after blessing → per-step snippet check (exit 8) |
| `rt-ledger-tamper` | `rt_ledger_tamper` | flip a Ledger-v2 record → `chainverify.verify_chain` |
| `rt-grant-replay` | `rt_grant_replay` | replay a spent grant nonce → `grants.verify_grant` (replay) |
| `rt-grant-expired` | `rt_grant_expired` | present an expired grant → `grants.verify_grant` (expired, ±60s skew) |
| `rt-grant-forged` | `rt_grant_forged` | tamper a signed grant claim → `grants.verify_grant` (bad_signature, offline) |

Each perk takes no inputs and writes `redteam.json` (`{attack, clean_accepted, refused, boundary_held}`);
exit 0 iff the boundary held.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, set `record_store`, then validate → compose →
compile → oversight → executor. Drive the whole corpus through govd to produce a governed refusal record.
