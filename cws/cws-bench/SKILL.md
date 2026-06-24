---
skill: cws-bench
name: Sandbox + channel overhead meter
perks: [bwrap-overhead, microvm-overhead, org-isolation, sse-latency, trace-propagation, settle-throughput, store-reconcile]
---

# cws-bench — Sandbox + channel overhead meter (V-BENCH, P2-T09)

Measure the cost of the governed execution boundary against the plan's budgets — from exod's **attested
meters** (P2-T07), never the agent's stopwatch. The doctrine: *the meter that bills must be the one the
isolated principal signed.*

## Perks
| perk | budget | measurable where |
|---|---|---|
| `bwrap-overhead` | per-step bwrap overhead **p95 ≤ 100 ms** | ✅ any Linux+bwrap host — drives N benign steps through exod into the bwrap SandboxProfile and reads exod's signed `meter.wall_ms` for each (measured p95 ≈ 4 ms, well within budget) |
| `microvm-overhead` | microVM **cold ≤ 1500 ms** + **warm ≤ 250 ms** | ✅ a `/dev/kvm`-capable Linux host — boots a real Firecracker microVM and times cold boot + warm snapshot-resume; skips (within:None) / raises elsewhere, never faked |

`bwrap-overhead` writes `bench.json` (`{backend, n, p50, p95, max, budget_ms, within}`) and exits **0 iff
`within` is true**. Set `N` (default 30) to widen the sample. The measurement logic is `infra/exec/bench.py`.

## The microVM budget — a REAL boot through /dev/kvm, never faked
P2-T09 also names microVM budgets (`microvm_cold_ms ≤ 1500`, `microvm_warm_ms ≤ 250`). `microvm-overhead`
measures them for real where hardware virtualization exists:

- **cold** — a fresh Firecracker process boots a pinned kernel (`firecracker-ci/v1.12 vmlinux-5.10.233`,
  sha256-verified) + a tiny runtime-built busybox rootfs; the timer stops when the guest's `/init` prints a
  **per-run random marker** (`CWS_BOOT_OK_<rand>`) on ttyS0. A process spawn, a sleep, or a stale log cannot
  produce that marker — it appears only if KVM ran the kernel to userspace and pid1 executed.
- **warm** — the VM is paused and Full-snapshotted; a **fresh** Firecracker process does
  `PUT /snapshot/load {resume_vm:true}` and the timer (started at the load call — the canonical FC resume
  cost) stops on the resumed guest's marker. Firecracker enforces the fresh-process invariant (a snapshot
  loads only on a virgin VM).

Where there is no `/dev/kvm` (macOS dev box: confirmed no `/dev/kvm`, 0 virt-capable CPUs; the plain compute
CI image) `bench_microvm()` returns `skipped` (within:None) and the perk exits non-zero — the budget is left
**honestly unmet, never fabricated**. The closing measurement runs on a GitHub-hosted `ubuntu-latest` runner
(nested KVM, `sudo chmod 666 /dev/kvm`) via `.github/workflows/bench-microvm.yml`, which drives this perk
through govd and emits the run-ledger `cws-observe/redeem` consumes to close **M3/SV-3 → 10/10**.

## Platform
`bwrap-overhead` needs Linux + bubblewrap; `microvm-overhead` needs Linux + `/dev/kvm` + the `firecracker`
binary (`test/case.json requires [python3, firecracker]`). Both SKIP on the macOS dev box / the plain compute
CI image and RUN where their backend exists (the exec image for bwrap; the hosted KVM runner for microVM).

## How to use it
Drive `bwrap-overhead` (optional `N`) through govd **inside the exec image** for P2-T07. Drive
`microvm-overhead` through govd **on a `/dev/kvm` host** for P2-T09 — the run-ledger feeds `cws-observe/redeem`.
