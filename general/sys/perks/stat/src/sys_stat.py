#!/usr/bin/env python3
"""sys_stat — governed host system metrics: CPU %, load average, memory, uptime, core count. The host's
resource pulse, so the fleet monitor can show node load alongside who-fired-what-where. Value-free (no process
list, no env, no paths — just numbers + the host name). Cross-platform: REAL /proc/stat CPU% on Linux; a
load-per-core estimate on hosts without /proc (macOS), labeled honestly in `cpu_method`. Writes stat.json;
exit 0 iff a CPU reading was obtained."""
import json
import os
import platform
import sys
import time


def _cpu_percent_linux():
    """Busy % over a short sample of /proc/stat (the kernel's own counters)."""
    def sample():
        with open("/proc/stat") as f:
            vals = [int(x) for x in f.readline().split()[1:]]
        idle = vals[3] + (vals[4] if len(vals) > 4 else 0)      # idle + iowait
        return idle, sum(vals)
    i1, t1 = sample()
    time.sleep(0.15)
    i2, t2 = sample()
    dt = t2 - t1
    return round((1 - (i2 - i1) / dt) * 100, 1) if dt > 0 else None


def _mem_linux():
    m = {}
    for line in open("/proc/meminfo"):
        f = line.split()
        if len(f) >= 2:
            m[f[0].rstrip(":")] = int(f[1])                     # kB
    total = m.get("MemTotal", 0)
    avail = m.get("MemAvailable", m.get("MemFree", 0))
    return {"total_mb": total // 1024, "available_mb": avail // 1024,
            "used_percent": round((1 - avail / total) * 100, 1) if total else None}


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    cores = os.cpu_count() or 1
    try:
        load1, load5, load15 = os.getloadavg()
    except (OSError, AttributeError):
        load1 = load5 = load15 = None

    if platform.system() == "Linux" and os.path.exists("/proc/stat"):
        cpu_percent, cpu_method = _cpu_percent_linux(), "proc_stat"
        mem = _mem_linux()
        try:
            uptime_s = int(float(open("/proc/uptime").read().split()[0]))
        except Exception:
            uptime_s = None
    else:                                                       # macOS / no /proc — honest load-per-core estimate
        cpu_percent = round(min(load1 / cores * 100, 100.0), 1) if load1 is not None else None
        cpu_method = "loadavg_per_core_estimate"
        mem = {"total_mb": None, "available_mb": None, "used_percent": None}
        uptime_s = None

    r = {"host": platform.node(), "os": platform.system(), "cores": cores,
         "cpu_percent": cpu_percent, "cpu_method": cpu_method,
         "loadavg": {"1m": load1, "5m": load5, "15m": load15},
         "load_per_core": round(load1 / cores, 3) if load1 is not None else None,
         "mem": mem, "uptime_seconds": uptime_s, "ok": cpu_percent is not None}
    with open(os.path.join(store, "stat.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "sys_stat", "host": r["host"], "cpu_percent": cpu_percent,
                      "cores": cores, "load1": load1}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
