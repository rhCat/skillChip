---
skill: cws-spc
name: Statistical Process Control
perks: [chart, drilldrift]
---

# cws-spc — instruments under SPC (P0.5)

An instrument is only trustworthy while it stays inside its **calibrated envelope**. This skill puts the
chip's detectors (and any measured process) under statistical process control: `chart` draws the control
chart — per-detector center line + UCL/LCL at `SIGMA_K` sigma — over a **time-series of measurements**
(e.g. FA/kfn per detector per run) against a **calibrated envelope**, and raises a 3-sigma-style **drift
alarm** on any breach. `drilldrift` is the falsifiability drill: the alarm must **fire** on a seeded
regression and stay **silent** on a benign series — both poles, or the instrument is either blind or noise.

## What to look out for
`spc.json` carries `{status: ok|drift, alarms[], charts:{<detector>: {mean, sigma, ucl, lcl, breaches[],
in_control, envelope_source}}}`. `envelope_source: baseline` means no calibrated envelope was supplied and
the first `BASELINE_N` points self-calibrated one — honest, but weaker than a calibrated reference.
`drilldrift.json` carries `{ok, legs: {seeded, benign}}`. A nonzero exit IS the drift/drill verdict.
LOGS TO CHECK: the per-tool JSON line + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `chart` | `cws_spc_chart` | control chart + drift alarm over a series vs its envelope — read-only, the exit code is the verdict |
| `drilldrift` | `cws_spc_drilldrift` | the oracle drill: seeded regression must alarm, benign must stay clean (bundled fixtures; vars-free) |

- **`chart`** — set `SERIES` (`{detector: [values]}` JSON). Optional `ENVELOPE` (`{detector: {mean,
  sigma}}`), `SIGMA_K` (default 3), `BASELINE_N` (default 8, self-calibration window when no envelope).
- **`drilldrift`** — claim with no vars for the bundled drill; `SEEDED`/`BENIGN`/`ENVELOPE` override for
  a custom corpus.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`, then
validate → compose → compile → oversight → executor.
