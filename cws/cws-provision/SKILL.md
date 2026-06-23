---
skill: cws-provision
name: Provision a cyberware fleet node
perks: [up]
---

# cws-provision — Provision a cyberware fleet node

Bring a fresh Lightsail / Linux box up as a cyberware fleet member in one governed run: base deps, **Docker**,
**Tailscale** (private-overlay join), and the **always-on syscontrol** (enable + `Restart=always` so the
services survive a crash AND a reboot). Operator-run with sudo; the porters use `sudo` when not already root.

This is the repeatable, audited form of `deploy/setup-lightsail-node.sh` — each step is a governed,
contract-bound porter recorded to the run-ledger as it runs.

## What to look out for
- **Operator-run, sudo-capable.** The porters install packages, write systemd units, and enable services —
  they need root (they call `sudo` when the invoking user is not root). This is NOT a confined/`nobody` run.
- **`DRY_RUN=1` plans only** — every porter prints the exact commands it WOULD run and emits its JSON without
  touching the host. The self-test runs this path, so it proves the skill through the governed channel
  hermetically (no apt, no daemon, no network).
- **Secrets via a `*_FILE` pointer, never plaintext.** The Tailscale auth key is read from `TS_AUTHKEY_FILE`
  (use a **non-ephemeral** key for an always-on node); it is never a plain var and never logged.
- **Tailscale is all-outbound** (NAT traversal) — joining the mesh needs **no inbound firewall change**.
- LOGS TO CHECK: each porter's `${RECORD_STORE}/provision_<step>.json` + `.log`, and the executor run-ledger.

## Perk
`up` runs the full sequence, each step a governed porter:

| step | tool | does |
|---|---|---|
| 1 | `provision_base` | apt deps (bwrap/uidmap/age/jq/curl/python3) + a non-login service user + `/etc/cyberware` |
| 2 | `provision_docker` | Docker Engine + compose v2 plugin, user→docker group, `enable --now docker` |
| 3 | `provision_tailscale` | install Tailscale + `tailscale up` join (`TS_AUTHKEY_FILE`, `TS_HOSTNAME`) |
| 4 | `provision_syscontrol` | enable services on boot + (optional) a `cyberware-agent` unit with `Restart=always` |

## Vars (all optional — sensible defaults; the self-test passes only `DRY_RUN=1`)
| var | default | for |
|---|---|---|
| `DRY_RUN` | `0` | `1` = plan only, change nothing |
| `CW_USER` / `CW_ETC` | `cyberware` / `/etc/cyberware` | the service user + config dir |
| `TS_AUTHKEY_FILE` | — | path to a file holding a **non-ephemeral** Tailscale auth key |
| `TS_HOSTNAME` | `cyberware-node` | the node's name in the tailnet |
| `ENABLE_SERVICES` | `docker tailscaled cyberware-govd` | services to `enable --now` |
| `AGENT_EXEC` | — | if set, install a `cyberware-agent` (brain) unit running this command, `Restart=always` |
| `AGENT_USER` | `cyberware` | the user the agent unit runs as |

## How to use it
1. Copy `ledger.json` → `task-ledger.json`, set `record_store` + the vars you need.
2. **Plan first:** set `DRY_RUN: "1"` and run it — read each `provision_*.json` to see exactly what it will do.
3. Run for real (omit `DRY_RUN`) **on the node, as a sudo-capable user**. Re-runnable: a present Docker /
   Tailscale / service is reported, not reinstalled.
