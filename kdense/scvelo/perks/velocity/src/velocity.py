#!/usr/bin/env python3
"""
Estimate RNA velocity and build the velocity graph.

Fits the splicing-kinetics velocity model and computes the cell-cell transition
graph, exactly as the upstream skill:
  * mode == 'dynamical'  -> scv.tl.recover_dynamics(n_jobs) first (full kinetics)
  * scv.tl.velocity(mode)
  * scv.tl.velocity_graph()

Writes a velocity-annotated .h5ad (adds layers['velocity'], uns['velocity_graph'],
and — in dynamical mode — the fit_* gene parameters).

Examples:
    python velocity.py preprocessed.h5ad --mode stochastic -o velocity.h5ad
    python velocity.py preprocessed.h5ad --mode dynamical --n-jobs 4 -o velocity.h5ad
"""

import argparse

from _common import add_io_args, configure_scvelo, info, load_adata, save_adata


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    add_io_args(p, default_output="velocity.h5ad")
    p.add_argument("--mode", default="dynamical",
                   choices=["stochastic", "deterministic", "dynamical", "steady_state"],
                   help="Velocity model (default: dynamical)")
    p.add_argument("--n-jobs", type=int, default=4,
                   help="Parallel jobs for dynamical recover_dynamics (default: 4)")
    args = p.parse_args()

    scv = configure_scvelo(figdir=args.figdir)
    adata = load_adata(args.input)
    info(f"Fitting velocity model: {args.mode}")

    if args.mode == "dynamical":
        scv.tl.recover_dynamics(adata, n_jobs=args.n_jobs)

    scv.tl.velocity(adata, mode=args.mode)
    scv.tl.velocity_graph(adata)
    info("Velocity graph computed")
    save_adata(adata, args.output)


if __name__ == "__main__":
    main()
