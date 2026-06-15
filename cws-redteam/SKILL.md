---
skill: cws-redteam
name: Kernel red-team corpus
perks: [rt-fs-escape, rt-write-rofs, rt-write-outside, rt-net-egress, rt-sysrq-reboot, rt-proc-sys-write, rt-mount, rt-device-raw, rt-forged-status, rt-grant-replay, rt-grant-expired, rt-grant-wrong-run, rt-grant-forged, rt-no-capability]
---

# cws-redteam — Kernel red-team corpus (V-RED, the M3 / SV-3 gate)

The kernel-tier adversarial **expected-refusal** corpus (plan v1.1, P2-T08). SV-3's promise is that
*execution becomes a **kernel**-enforced boundary* — so this corpus proves the boundary holds **with the
in-process software scan DISABLED**: each perk mounts a real attack and routes it **through the `exod`
daemon** into the **bwrap `SandboxProfile`** (or against exod's signed-status channel), and asserts the
boundary REFUSED it. The refusal is therefore the Linux kernel (namespaces, bind mounts, masked `/proc`,
dropped capabilities) or the Ed25519 channel — never a scanner.

Doctrine (meta-rule M4): *a recorded refusal is evidence.* Each perk exits **0 iff the boundary held** —
the attack was refused AND a benign-control **oracle** was accepted (so a gate that silently goes no-op,
accepting everything, fails the corpus instead of passing it). 14 behaviours (≥ 12 required), two families:

| family | perks | what the kernel/channel must refuse |
|---|---|---|
| **sandbox** | rt-fs-escape · rt-write-rofs · rt-write-outside · rt-net-egress · rt-sysrq-reboot · rt-proc-sys-write · rt-mount · rt-device-raw | a hostile command run by exod inside the sandbox is blocked by the kernel (exod's SIGNED status is `error`, not `ok`) |
| **channel** | rt-forged-status · rt-grant-replay · rt-grant-expired · rt-grant-wrong-run · rt-grant-forged · rt-no-capability | a forged status, or a replayed / expired / cross-run / tampered / capability-less grant, is refused on exod's channel |

The attack logic lives in `infra/exec/redteam.py` (the shared corpus), exercised by `tests/test_redteam.py`.
Each perk's `src/rt_*.py` PINS exactly one behaviour (the `ATTACK` is baked, not a runtime arg), so the
SKILL itself encodes the corpus.

## Platform — this runs on a real kernel only
The boundary is the Linux kernel, so every perk needs **Linux + bubblewrap** (even the channel perks, whose
oracle runs a benign step through the sandbox). Each perk's `test/case.json` declares `requires: [python3,
bwrap]`, so the self-tests SKIP where bwrap is absent (the macOS dev box, the plain compute CI image) and RUN
for real in the **exec image** (`infra/exec/Dockerfile.exec`). The governed gate is driven inside that image
— `docker run --privileged` so the sandbox host can drop each step into an unprivileged namespace.

## What it redeems
P2-T08 and the kernel-validated P2 attack-surface cone — **P2-T01** (grants), **P2-T02** (exod), **P2-T03**
(SandboxProfile), **P2-T08** (this corpus) — all `validated_by: cws-redteam`. Together with the `cws-bench`
perf branch (P2-T07 / P2-T09) this closes **M3 / SV-3**.

## What to look out for
Each perk writes `redteam.json` (`{attack, family, held, refused, detail}`) and exits 0 iff `held`. A
nonzero exit means a BREACH (the attack succeeded or the oracle was refused) — read `detail`
(`attack_status=…`, `oracle_ok=…`, or the refusal `reason`). LOGS: that file + the executor run-ledger.

## How to use it
Pick a perk (e.g. `rt-grant-replay`); it takes no inputs (the behaviour is baked). Drive the whole corpus
through govd **inside the exec image** to produce the run-ledgers `cws-observe/redeem` reads.
