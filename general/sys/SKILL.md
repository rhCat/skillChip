---
skill: sys
name: Host system metrics
perks: [stat]
---

# sys — host system metrics (governed)

A general-tool skill that reports the host's resource pulse through the governed channel, so a node's load is
visible in the fleet monitor right alongside *who fired what, where*. Read-only and **value-free** — it emits
numbers (CPU %, load average, memory, uptime, core count) and the host name, never a process list, env, or
path. On a **body** it runs confined via exod (it reads the limb's own `/proc`); on a cooperative **anchor**
it reports that host. Real `/proc/stat` CPU% on Linux; an honest load-per-core estimate on hosts without
`/proc` (macOS), labeled in `cpu_method`.

## Perks
| perk | tools | what |
|---|---|---|
| `stat` | `python3` | `stat.json` = `{host, os, cores, cpu_percent, cpu_method, loadavg{1m,5m,15m}, load_per_core, mem{total_mb,available_mb,used_percent}, uptime_seconds}`. Exit 0 iff a CPU reading was obtained. No inputs. |
