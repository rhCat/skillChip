#!/usr/bin/env python3
"""
Shared helpers for the scVelo perk toolkit.

Every per-operation CLI in this cartridge imports from this module so that
data loading, saving, scVelo settings, and logging behave consistently.
This file is NOT a CLI itself; import it:

    from _common import load_adata, save_adata, configure_scvelo, info

The functions wrap scvelo / scanpy exactly as the upstream K-Dense skill does
(see scripts/rna_velocity_workflow.py). scvelo is imported lazily so the thin
porter can write a placeholder artifact and still pass when the library is
absent (e.g. the offline skilltest harness on python3.9).
"""

import os
import sys


def info(msg):
    """Print a progress message with a marker."""
    print(f"[scvelo] {msg}", flush=True)


def die(msg, code=1):
    """Print an error and exit."""
    print(f"Error: {msg}", file=sys.stderr, flush=True)
    sys.exit(code)


def _import_scvelo():
    try:
        import scvelo as scv  # noqa: F401
        return scv
    except ImportError:
        die("scvelo not installed. Install with: pip install scvelo")


def _import_scanpy():
    try:
        import scanpy as sc  # noqa: F401
        return sc
    except ImportError:
        die("scanpy not installed. Install with: pip install scanpy")


def configure_scvelo(figdir="figures", verbosity=2, dpi=120):
    """Apply consistent scVelo settings and return the scvelo module.

    Mirrors the upstream skill: verbosity, figure params, and figdir are set
    so plotting calls produce predictable filenames under record_store.
    """
    scv = _import_scvelo()
    scv.settings.verbosity = verbosity
    try:
        scv.settings.set_figure_params("scvelo", dpi=dpi)
    except Exception:
        pass
    scv.settings.figdir = figdir
    os.makedirs(figdir, exist_ok=True)
    return scv


def load_adata(path):
    """Load an AnnData object from .h5ad (scVelo/Scanpy) or .loom (velocyto)."""
    scv = _import_scvelo()
    if not os.path.exists(path):
        die(f"input not found: {path}")
    lower = path.lower()
    if lower.endswith(".loom"):
        info(f"Reading velocyto loom: {path}")
        return scv.read(path, cache=True)
    if lower.endswith(".h5ad"):
        return scv.read(path)
    # Fall back to scvelo's general reader (handles .loom/.h5ad/.csv).
    return scv.read(path)


def save_adata(adata, path):
    """Write an AnnData object to .h5ad, creating parent dirs as needed."""
    parent = os.path.dirname(os.path.abspath(path))
    os.makedirs(parent, exist_ok=True)
    adata.write_h5ad(path)
    info(f"Wrote {path}  ({adata.n_obs} cells x {adata.n_vars} genes)")


def require_velocity_layers(adata):
    """Assert the spliced/unspliced layers RNA velocity requires are present."""
    if "spliced" not in adata.layers:
        die("Missing 'spliced' layer. Run velocyto/STARsolo first.")
    if "unspliced" not in adata.layers:
        die("Missing 'unspliced' layer. Run velocyto/STARsolo first.")


def add_io_args(parser, default_output=None):
    """Attach the standard input/output/figdir arguments to an argparse parser."""
    parser.add_argument("input", help="Input AnnData (.h5ad) or velocyto (.loom)")
    parser.add_argument("-o", "--output", default=default_output,
                        help="Output .h5ad path" +
                             (f" (default: {default_output})" if default_output else ""))
    parser.add_argument("--figdir", default="figures",
                        help="Directory for saved figures (default: figures)")
    return parser
