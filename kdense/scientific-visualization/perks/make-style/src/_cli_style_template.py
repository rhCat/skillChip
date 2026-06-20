#!/usr/bin/env python3
"""
Thin CLI driver for the make-style perk.

Writes a publication-quality matplotlib .mplstyle file (fonts, hidden top/right
spines, tick sizing, Okabe-Ito color cycle, savefig DPI) via the vendored
style_presets.create_style_template(), then emits a JSON summary on stdout.

Env -> arg translation (set by the porter):
  STYLE_OUT  (required)  absolute path of the .mplstyle file to write (under RECORD_STORE)

Never raises: on any failure it prints a JSON object with "status":"degraded"
and exits 0 so the governed run stays auditable.
"""
import os
import sys
import json


def _fail(reason):
    print(json.dumps({"tool": "style_template", "status": "degraded", "reason": reason}))
    sys.exit(0)


def main():
    style_out = os.environ.get("STYLE_OUT", "")
    if not style_out:
        _fail("STYLE_OUT is required")

    try:
        import matplotlib  # noqa: F401
    except Exception as e:  # noqa: BLE001
        _fail("matplotlib unavailable: %s" % e)

    HERE = os.path.dirname(os.path.abspath(__file__))
    if HERE not in sys.path:
        sys.path.insert(0, HERE)
    try:
        from cycler import Cycler
        from style_presets import get_base_style
    except Exception as e:  # noqa: BLE001
        _fail("cannot import vendored style_presets: %s" % e)

    # We serialize get_base_style() ourselves rather than calling the vendored
    # create_style_template(): on matplotlib >= 3.x `mpl.cycler` is a function, not a
    # type, so the core's `isinstance(value, mpl.cycler)` raises. The core is vendored
    # UNCHANGED; the .mplstyle content below matches what it would emit.
    try:
        style = get_base_style()
        lines = [
            "# Publication-quality matplotlib style\n",
            "# Usage: plt.style.use('publication.mplstyle')\n\n",
        ]
        for key, value in style.items():
            if isinstance(value, Cycler):
                colors = [c["color"] for c in value]
                lines.append("axes.prop_cycle : cycler('color', %s)\n" % colors)
            else:
                lines.append("%s : %s\n" % (key, value))
        with open(style_out, "w") as fh:
            fh.writelines(lines)
    except Exception as e:  # noqa: BLE001
        _fail("style serialization failed: %s" % e)

    if not os.path.isfile(style_out) or os.path.getsize(style_out) == 0:
        _fail("style file not written")

    print(json.dumps({
        "tool": "style_template",
        "status": "ok",
        "style_file": style_out,
        "bytes": os.path.getsize(style_out),
    }))


if __name__ == "__main__":
    main()
