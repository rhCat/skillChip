---
skill: matplotlib
name: Matplotlib (plotting)
perks: [render_plot, configure_style]
---

# matplotlib — Matplotlib (plotting)

Render a matplotlib plot to an image (read-only) or generate a custom `.mplstyle` style sheet from a preset.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named output file + the executor run-ledger.
Both tools force the non-interactive `Agg` backend (`MPLBACKEND=Agg`), so `plt.show()` never blocks.

## Perks
| perk | tool | nature |
|---|---|---|
| `render_plot` | `plot_render` | read-only / safe — renders a template plot (line/scatter/bar/histogram/heatmap/contour/box/violin/3d/all) to an image file |
| `configure_style` | `style_config` | read-only / safe — writes a custom `.mplstyle` sheet (and optional preview PNG) from a named preset |

The `render_plot` perk runs the vendored `plot_template.py` core, rendering the requested plot type to
`PLOT_OUT` (default `plot.png`) under `record_store`. The `configure_style` perk runs the vendored
`style_configurator.py` core, emitting a `.mplstyle` file (and `*_preview.png`) under `record_store`.
Both are read-only/local file producers and declared `destructive: false`.

## How to use it
Pick a perk (`render_plot` or `configure_style`), copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `matplotlib` — MIT (see LICENSE.txt).
