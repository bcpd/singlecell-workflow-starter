#!/usr/bin/env python

"""Trajectory inference demo using Scanpy's built-in Paul et al. hematopoiesis dataset.

This script demonstrates:
- Loading a public single-cell differentiation dataset.
- Clustering cells.
- Running PAGA.
- Computing diffusion pseudotime from a selected root cell.
"""

from __future__ import annotations

import argparse

import numpy as np
import scanpy as sc

from utils import ensure_outdir


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Run Scanpy PAGA trajectory workflow on paul15.")
    parser.add_argument("--outdir", default="results/scanpy_paga_paul15", help="Output directory")
    parser.add_argument("--root-cell-index", type=int, default=0, help="Root cell index for diffusion pseudotime")
    return parser.parse_args()


def main() -> None:
    """Run PAGA and diffusion pseudotime."""
    args = parse_args()
    outdir = ensure_outdir(args.outdir)
    sc.settings.figdir = str(outdir)

    # Load built-in Paul et al. myeloid/erythroid differentiation dataset.
    adata = sc.datasets.paul15()

    # Basic preprocessing for trajectory analysis.
    sc.pp.recipe_zheng17(adata)
    sc.tl.pca(adata, svd_solver="arpack")
    sc.pp.neighbors(adata, n_neighbors=4, n_pcs=20)
    sc.tl.leiden(adata, resolution=1.0, key_added="leiden")

    # Compute PAGA graph from Leiden clusters.
    sc.tl.paga(adata, groups="leiden")
    sc.pl.paga(adata, save="_paul15.png", show=False)

    # Use PAGA initialization for UMAP.
    sc.tl.umap(adata, init_pos="paga")
    sc.pl.umap(adata, color=["leiden"], save="_paul15_leiden.png", show=False)

    # Select a root cell for diffusion pseudotime.
    root_index = min(max(args.root_cell_index, 0), adata.n_obs - 1)
    adata.uns["iroot"] = np.flatnonzero(np.arange(adata.n_obs) == root_index)[0]

    # Compute diffusion pseudotime.
    sc.tl.dpt(adata)
    sc.pl.umap(adata, color=["dpt_pseudotime"], save="_paul15_pseudotime.png", show=False)

    # Save outputs.
    adata.obs.to_csv(outdir / "paul15_cell_metadata_with_pseudotime.csv")
    adata.write_h5ad(outdir / "paul15_paga_dpt.h5ad")


if __name__ == "__main__":
    main()
