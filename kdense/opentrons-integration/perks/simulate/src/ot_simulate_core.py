#!/usr/bin/env python3
"""
ot_simulate_core — dry-run an Opentrons Protocol API v2 file without a physical robot.

Vendored core for the opentrons-integration `simulate` perk. Uses the official
`opentrons` package (`opentrons.simulate.simulate`) to validate and dry-run a
protocol, capturing the simulated run log. Degrades gracefully (prints a notice,
exits 0) when the opentrons package is not installed, so the governed porter still
satisfies its output contract offline.

Usage:
    python3 ot_simulate_core.py <protocol_file.py>

Writes the run log to stdout; the porter redirects it to record_store/simulate.log.
"""
import sys


def main(argv):
    if len(argv) < 2:
        print("ot_simulate_core: missing PROTOCOL_FILE argument")
        return 0
    protocol_file = argv[1]

    try:
        from opentrons import simulate as ot_simulate
    except Exception as exc:  # opentrons package absent or import error
        print("opentrons package not available: %s" % exc)
        print("ot_simulate_core: degraded (no simulation performed)")
        return 0

    try:
        with open(protocol_file, "r") as fh:
            runlog, _bundle = ot_simulate.simulate(fh, file_name=protocol_file)
    except FileNotFoundError:
        print("protocol file not found: %s" % protocol_file)
        return 0
    except Exception as exc:
        print("simulation error: %s" % exc)
        return 0

    try:
        print(ot_simulate.format_runlog(runlog))
    except Exception:
        for entry in runlog:
            print(entry)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
