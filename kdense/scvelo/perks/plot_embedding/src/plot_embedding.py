#!/usr/bin/env python3
"""
Render a velocity embedding plot to PNG.

Projects RNA velocity onto a 2D embedding (basis, e.g. umap) and renders one of
the upstream skill's plot styles:
  * stream  -> scv.pl.velocity_embedding_stream  (clean streamlines)
  * grid    -> scv.pl.velocity_embedding_grid
  * arrows  -> scv.pl.velocity_embedding          (per-cell arrows)

Uses a non-interactive matplotlib backend and saves directly to --output.

Examples:
    python plot_embedding.py velocity.h5ad --kind stream --color clusters -o stream.png
    python plot_embedding.py velocity.h5ad --kind arrows --basis umap -o arrows.png
"""

import argparse

import matplotlib
matplotlib.use("Agg")  # Non-interactive backend (must precede pyplot import)

from _common import configure_scvelo, info, load_adata


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("input", help="Velocity-annotated AnnData (.h5ad)")
    p.add_argument("-o", "--output", default="velocity_embedding.png",
                   help="Output PNG path (default: velocity_embedding.png)")
    p.add_argument("--figdir", default="figures",
                   help="Directory for saved figures (default: figures)")
    p.add_argument("--kind", default="stream",
                   choices=["stream", "grid", "arrows"],
                   help="Embedding plot style (default: stream)")
    p.add_argument("--basis", default="umap",
                   help="Embedding basis (default: umap)")
    p.add_argument("--color", default=None,
                   help="obs column to color by (e.g. clusters/leiden)")
    args = p.parse_args()

    scv = configure_scvelo(figdir=args.figdir)
    adata = load_adata(args.input)

    kwargs = dict(basis=args.basis, show=False, save=False)
    if args.color:
        kwargs["color"] = args.color

    if args.kind == "stream":
        ax = scv.pl.velocity_embedding_stream(adata, **kwargs)
    elif args.kind == "grid":
        ax = scv.pl.velocity_embedding_grid(adata, **kwargs)
    else:  # arrows
        ax = scv.pl.velocity_embedding(adata, arrow_length=3, arrow_size=2, **kwargs)

    import matplotlib.pyplot as plt
    fig = getattr(ax, "figure", None) or plt.gcf()
    fig.savefig(args.output, dpi=150, bbox_inches="tight")
    info(f"Wrote {args.kind} embedding plot -> {args.output}")


if __name__ == "__main__":
    main()
