#!/usr/bin/env python3
"""
Thin CLI driver for the export-journal perk.

Reads a CSV of numeric columns (first column = x, remaining columns = y series),
builds a publication-styled matplotlib line figure, and saves it using a specific
journal's required formats + DPI via the vendored figure_export.save_for_journal().

Env -> arg translation (set by the porter):
  DATA_CSV     (required)  path to a CSV with a header row + numeric columns
  OUT_BASE     (required)  output base path WITHOUT extension (under RECORD_STORE)
  JOURNAL      (optional)  nature|science|cell|plos|acs|ieee, default "nature"
  FIGURE_TYPE  (optional)  line_art|photo|combination, default "combination"

Emits a single JSON object on stdout. Never raises: on any failure it prints a
JSON object with "status":"degraded" and exits 0 so the governed run stays auditable.
"""
import os
import sys
import json


def _fail(reason):
    print(json.dumps({"tool": "journal_export", "status": "degraded", "reason": reason}))
    sys.exit(0)


def main():
    data_csv = os.environ.get("DATA_CSV", "")
    out_base = os.environ.get("OUT_BASE", "")
    journal = os.environ.get("JOURNAL", "nature").strip().lower()
    figure_type = os.environ.get("FIGURE_TYPE", "combination").strip().lower()

    if not data_csv or not out_base:
        _fail("DATA_CSV and OUT_BASE are required")

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        import numpy as np
    except Exception as e:  # noqa: BLE001
        _fail("matplotlib/numpy unavailable: %s" % e)

    HERE = os.path.dirname(os.path.abspath(__file__))
    if HERE not in sys.path:
        sys.path.insert(0, HERE)
    try:
        from figure_export import save_for_journal
    except Exception as e:  # noqa: BLE001
        _fail("cannot import vendored figure_export: %s" % e)

    try:
        import csv
        with open(data_csv, newline="") as fh:
            reader = csv.reader(fh)
            rows = [r for r in reader if r]
        if len(rows) < 2:
            _fail("CSV has no data rows")
        header = rows[0]
        data = np.array([[float(c) for c in r] for r in rows[1:]], dtype=float)
    except Exception as e:  # noqa: BLE001
        _fail("could not parse CSV: %s" % e)

    if data.shape[1] < 2:
        _fail("CSV needs at least 2 columns (x + 1 series)")

    x = data[:, 0]
    fig, ax = plt.subplots(figsize=(3.5, 2.5))
    for j in range(1, data.shape[1]):
        ax.plot(x, data[:, j], label=header[j] if j < len(header) else "series%d" % j)
    ax.set_xlabel(header[0] if header else "x")
    ax.set_ylabel("value")
    ax.legend(frameon=False)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)

    import contextlib
    try:
        with contextlib.redirect_stdout(sys.stderr):
            saved = save_for_journal(fig, out_base, journal=journal, figure_type=figure_type)
        saved = [str(p) for p in saved]
    except Exception as e:  # noqa: BLE001
        plt.close(fig)
        _fail("save_for_journal failed: %s" % e)
    plt.close(fig)

    print(json.dumps({
        "tool": "journal_export",
        "status": "ok",
        "journal": journal,
        "figure_type": figure_type,
        "saved": saved,
        "n_series": int(data.shape[1] - 1),
        "n_points": int(data.shape[0]),
    }))


if __name__ == "__main__":
    main()
