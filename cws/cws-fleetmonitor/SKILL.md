---
skill: cws-fleetmonitor
name: Cyberware Fleet Monitor
perks: [status, deploy, down]
---

# cws-fleetmonitor — the fleet dashboard as a supervised, self-healing service

The cross-node **fleetdash** (`infra.tool.fleetdash`) mirrors every node's ledger onto one control-host
dashboard. Run bare, it's an unsupervised process that dies on reboot and — worse — can **silently wedge**
(the background mirror loop freezes while the process stays alive, so the view goes stale with no crash).
This skill governs its whole lifecycle as a **parameterized, host-agnostic** service.

> Nothing about your fleet is baked in. Host, port, interpreter, paths, node names — all are vars with sane
> defaults, resolved at deploy time (e.g. `HOST_BIND=auto` → this host's tailnet IP; `HEARTBEAT_NODE` → the
> first node in your roster). The skill renders into **your** deployment dirs, never the repo.

## Perks

- **`deploy`** *(destructive)* — render a launcher + a **freeze-watchdog** + an OS-native supervision unit
  (**launchd** on macOS / **systemd `--user`** on Linux) and load them. Two failure modes are covered:
  *death* → the supervisor restarts it (KeepAlive / `Restart=always`); *wedge* → the watchdog kicks it when
  the durable mirror stops advancing (`mtime` of the heartbeat node's index older than `MIRROR_INTERVAL*6+30s`).
  Survives reboot (macOS launchd runs at login; on Linux `deploy` runs `loginctl enable-linger` so the
  `--user` manager starts at **boot**, not just login). Writes a value-free `deploy.json`.
- **`status`** *(read-only)* — is the unit loaded, is the port serving (a fleetdash-identifying marker, not
  merely any 200), and is the mirror loop **fresh**? Catches a frozen-but-alive loop **and** a never-started
  one (a missing heartbeat reads `no_heartbeat`, not healthy). The check itself always **exits 0**; the health
  is in the record — read `status.json` (`healthy`/`supervisor_loaded`/`serving`/`snapshot_fresh`), not the exit code.
- **`down`** *(destructive)* — stop + unregister the unit and its watchdog and remove the rendered artifacts.
  The **durable mirror is preserved** — teardown is about the service, not the recorded history.

## Vars (all optional — defaults in parens)

| var | meaning | default |
|---|---|---|
| `HOST_BIND` | interface to bind; `auto` = this host's tailnet IP | `auto` (→ `tailscale ip -4`, else `127.0.0.1`) |
| `PORT` | dashboard port | `8787` |
| `MIRROR_INTERVAL` | background sweep seconds | `15` |
| `FLEET_CONFIG` | the roster json | `$HOME/.cyberware/fleet.json` |
| `MIRROR_DIR` | durable mirror dir | `$HOME/.cyberware/fleet-ledgers` |
| `HEARTBEAT_NODE` | node whose mirror `mtime` = the loop's heartbeat | first node in `FLEET_CONFIG` |
| `PYTHON` | interpreter that can import `infra` | `python3` |
| `CYBERWARE_ROOT` | the cyberware checkout | `$HOME/hunyuan/cyberware` |
| `LABEL` | service label / unit name | `com.cyberware.fleetdash` |
| `FLEET_HOME` · `LOG_DIR` | where rendered scripts / logs live | `$HOME/fleet` · `$HOME/.cyberware` |
| `KEEP_SCRIPTS` | (`down` only) `1` = leave the rendered launcher/watchdog on disk; remove the unit only | unset |

## Security

The dashboard has **no app-auth** and carries a monitor-token read proxy, so a non-loopback `HOST_BIND`
(tailnet / `0.0.0.0`) is served only with the dashboard's explicit `FLEETDASH_ALLOW_OPEN` ack that `deploy`
sets — pair it with **deny-by-default tailnet ACLs** gating `PORT`. `HOST_BIND=auto` binds the tailnet IP,
never the LAN or public interface; it falls back to loopback, never fail-open.

## Example

```json
{ "skill": "cws-fleetmonitor", "perk": "deploy",
  "record_store": "<abs dir>",
  "vars": { "HOST_BIND": "auto", "PORT": "8787", "MIRROR_INTERVAL": "15" } }
```
