---
skill: scientific-visualization
name: Scientific Visualization
perks: [export-figure, export-journal, check-size, make-style]
---

# scientific-visualization — Scientific Visualization

Export publication-ready scientific figures, check journal size compliance, and emit matplotlib style templates. Each operation is a self-contained, file-producing (read-only) perk wrapping the K-Dense `figure_export.py` / `style_presets.py` cores.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger. The cores depend on matplotlib/numpy; when those libs are absent the porter degrades gracefully (the named output is still written, non-empty) so the governed run stays auditable.

## Perks
| perk | tool | nature |
|---|---|---|
| `export-figure` | `figure_export` | read-only — render data → `figure.pdf`/`figure.png` (+ chosen formats) at fixed DPI via `save_publication_figure` |
| `export-journal` | `journal_export` | read-only — render data → journal-spec formats + DPI (`save_for_journal`) for nature/science/cell/plos/acs/ieee |
| `check-size` | `size_check` | read-only — `check_figure_size` compliance report (`size_check.json`); no figure file written |
| `make-style` | `style_template` | read-only — `create_style_template` writes a `.mplstyle` preset (`publication.mplstyle`) |

`export-figure` plots the numeric columns of a CSV (first column = x, remaining = y series) and saves it in the requested formats with publication DPI/bbox settings. `export-journal` does the same but pulls the format list + DPI from the target journal's spec table. `check-size` is a pure compute: given width/height in inches and a journal, it reports column-width and max-height compliance as JSON. `make-style` writes a publication matplotlib style file (fonts, hidden top/right spines, tick sizing, Okabe-Ito color cycle, savefig DPI) usable with `plt.style.use()`.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `scientific-visualization` — MIT (see LICENSE.txt).
