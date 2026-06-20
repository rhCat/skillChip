#!/usr/bin/env python3
"""
Thin CLI driver for the check-size perk.

Builds a zero-content matplotlib figure of the given width/height (inches) and runs
the vendored figure_export.check_figure_size() to report whether the dimensions
comply with a journal's column-width + max-height specifications.

Env -> arg translation (set by the porter):
  WIDTH_IN   (required)  figure width in inches
  HEIGHT_IN  (required)  figure height in inches
  JOURNAL    (optional)  nature|science|cell|plos|acs, default "nature"

Emits the compliance dict as a single JSON object on stdout. Never raises: on any
failure it prints a JSON object with "status":"degraded" and exits 0 so the governed
run stays auditable.
"""
import os
import sys
import json


def _fail(reason):
    print(json.dumps({"tool": "size_check", "status": "degraded", "reason": reason}))
    sys.exit(0)


def main():
    try:
        width_in = float(os.environ.get("WIDTH_IN", ""))
        height_in = float(os.environ.get("HEIGHT_IN", ""))
    except ValueError:
        _fail("WIDTH_IN and HEIGHT_IN must be numeric")
    journal = os.environ.get("JOURNAL", "nature").strip().lower()

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except Exception as e:  # noqa: BLE001
        _fail("matplotlib unavailable: %s" % e)

    HERE = os.path.dirname(os.path.abspath(__file__))
    if HERE not in sys.path:
        sys.path.insert(0, HERE)
    try:
        from figure_export import check_figure_size
    except Exception as e:  # noqa: BLE001
        _fail("cannot import vendored figure_export: %s" % e)

    import contextlib
    try:
        fig = plt.figure(figsize=(width_in, height_in))
        with contextlib.redirect_stdout(sys.stderr):
            result = check_figure_size(fig, journal=journal)
        plt.close(fig)
    except Exception as e:  # noqa: BLE001
        _fail("check_figure_size failed: %s" % e)

    result["tool"] = "size_check"
    result["status"] = "ok"

    # check_figure_size returns numpy scalars (np.float64 / np.bool_) that json can't
    # serialize directly; coerce the whole structure to native Python types.
    def _native(o):
        if isinstance(o, dict):
            return {k: _native(v) for k, v in o.items()}
        if isinstance(o, (list, tuple)):
            return [_native(v) for v in o]
        if hasattr(o, "item"):  # numpy scalar
            try:
                return o.item()
            except Exception:  # noqa: BLE001
                return o
        return o

    print(json.dumps(_native(result)))


if __name__ == "__main__":
    main()
