#!/usr/bin/env python3
"""
Load velocyto output into a single AnnData .h5ad for RNA velocity.

Reads a velocyto .loom file (which carries spliced/unspliced layers) and, when
a processed Scanpy .h5ad is given, merges its metadata (UMAP, clusters) onto the
velocity layers via scv.utils.merge — exactly as the upstream skill's
load_from_loom() does.

Examples:
    python load.py velocyto.loom -o data.h5ad
    python load.py velocyto.loom --processed processed.h5ad -o data.h5ad
"""

import argparse

from _common import add_io_args, configure_scvelo, info, load_adata, save_adata


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    add_io_args(p, default_output="data.h5ad")
    p.add_argument("--processed", default=None,
                   help="Optional pre-processed Scanpy .h5ad to merge (UMAP/clusters)")
    args = p.parse_args()

    scv = configure_scvelo(figdir=args.figdir)
    adata_loom = load_adata(args.input)

    if args.processed:
        info(f"Merging processed metadata from {args.processed}")
        import scanpy as sc
        adata_processed = sc.read_h5ad(args.processed)
        adata = scv.utils.merge(adata_processed, adata_loom)
    else:
        adata = adata_loom

    info(f"Loaded {adata.n_obs} cells x {adata.n_vars} genes; "
         f"layers: {', '.join(adata.layers.keys())}")
    save_adata(adata, args.output)


if __name__ == "__main__":
    main()
