---
skill: cws-bench
name: Sandbox + channel overhead meter
perks: [bwrap-overhead]
---

# cws-bench — Sandbox + channel overhead meter (V-BENCH, P2-T09)

Measure the cost of the governed execution boundary against the plan's budgets — from exod's **attested
meters** (P2-T07), never the agent's stopwatch. The doctrine: *the meter that bills must be the one the
isolated principal signed.*

## Perks
| perk | budget | measurable here |
|---|---|---|
| `bwrap-overhead` | per-step bwrap overhead **p95 ≤ 100 ms** | ✅ — drives N benign steps through exod into the bwrap SandboxProfile and reads exod's signed `meter.wall_ms` for each (measured p95 ≈ 4 ms, well within budget) |

`bwrap-overhead` writes `bench.json` (`{backend, n, p50, p95, max, budget_ms, within}`) and exits **0 iff
`within` is true**. Set `N` (default 30) to widen the sample. The measurement logic is `infra/exec/bench.py`.

## Honest scope — the microVM budgets are NOT measurable without /dev/kvm
P2-T09 also names microVM budgets (`microvm_cold_ms ≤ 1500`, `microvm_warm_ms ≤ 250`). A microVM backend
(Firecracker / cloud-hypervisor) needs `/dev/kvm` + nested virtualization, which **Docker Desktop on macOS
does not provide** (confirmed: no `/dev/kvm`, 0 virt-capable CPUs). `infra/exec/bench.bench_microvm()`
therefore reports `skipped` — the budget is left **honestly unmet, never faked**. This skill ships only the
budget it can measure; the microVM branch waits for a KVM-capable Linux host. Consequently cws-bench can
validate **P2-T07** (exod-attested meters, via the bwrap overhead) but **P2-T09's full acceptance is not met
here** — M3/SV-3 reaches 9/10, not 10/10, on this hardware.

## Platform
Every perk needs Linux + bubblewrap (`test/case.json requires [python3, bwrap]`), so it SKIPS on the macOS
dev box / the plain compute CI image and RUNS in the exec image (`infra/exec/Dockerfile.exec`).

## How to use it
Pick `bwrap-overhead` (no inputs beyond optional `N`). Drive it through govd **inside the exec image** to
produce the run-ledger `cws-observe/redeem` reads for P2-T07.
