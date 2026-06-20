#!/usr/bin/env python3
"""
ot_scaffold_core — emit a vendored Opentrons Protocol API v2 template file.

Vendored core for the opentrons-integration `scaffold-*` perks. Pure Python
stdlib: reads a template (.py) that ships next to this module and writes it to a
destination path. No third-party dependency — always runs offline.

Usage:
    python3 ot_scaffold_core.py <template_name.py> <dest_path>

Prints the rendered protocol to stdout; the porter writes the file at <dest_path>
and redirects this audit text to the run log.
"""
import os
import sys


def main(argv):
    if len(argv) < 3:
        print("ot_scaffold_core: usage: <template_name> <dest_path>")
        return 0
    template_name = argv[1]
    dest_path = argv[2]
    here = os.path.dirname(os.path.abspath(__file__))
    template_path = os.path.join(here, template_name)

    try:
        with open(template_path, "r") as fh:
            content = fh.read()
    except Exception as exc:
        print("template not found: %s (%s)" % (template_path, exc))
        return 0

    try:
        with open(dest_path, "w") as out:
            out.write(content)
    except Exception as exc:
        print("could not write protocol: %s (%s)" % (dest_path, exc))
        return 0

    print("scaffolded %s -> %s (%d bytes)" % (template_name, dest_path, len(content)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
