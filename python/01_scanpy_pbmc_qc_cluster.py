#!/usr/bin/env python

"""Run a production-oriented Scanpy workflow for a 10x filtered matrix."""

from __future__ import annotations

import argparse
import shutil
import sys
from importlib.metadata import PackageNotFoundError, version
from pathlib import Path

import pandas as pd
import scanpy as sc

from utils import (
    CONTRACT_VERSION,
    default_mt_prefix,
    ensure_outdir,
    mitochondrial_gene_mask,
    write_json,
    write_output_manifest,
)


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Run Scanpy QC, clustering, and marker discovery.")
    parser.add_argument("--input", required=True, help="10x matrix directory")
    parser.add_argument("--outdir", default="results/scanpy_pbmc", help="Output directory")
    parser.add_argument("--sample", "--project", dest="sample", default="pbmc", help="Sample/project name")
    parser.add_argument("--species", default="human", help="Species label used for metadata defaults")
    parser.add_argument("--genome", default="", help="Genome/reference label recorded in run metadata")
    parser.add_argument("--mt-prefix", default=None, help="Mitochondrial gene prefix")
    parser.add_argument(
        "--min-features",
        "--min-genes",
        dest="min_features",
        type=int,
        default=200,
        help="Minimum detected genes per cell",
    )
    parser.add_argument(
        "--max-features",
        "--max-genes",
        dest="max_features",
        type=int,
        default=2500,
        help="Maximum detected genes per cell",
    )
    parser.add_argument("--max-mt", type=float, default=5.0, help="Maximum mitochondrial percent")
    parser.add_argument(
        "--cluster-resolution",
        type=float,
        default=0.5,
        help="Leiden clustering resolution",
    )
    return parser.parse_args()


def package_version(package: str) -> str:
    """Return an installed package version or a stable missing marker."""
    try:
        return version(package)
    except PackageNotFoundError:
        return "not-installed"


def write_legacy_run_summary(summary: dict, path: Path) -> None:
    """Write the original text summary for existing users."""
    fields = {
        "project": summary["sample"],
        "cells_after_qc": summary["cells_after_qc"],
        "genes_used_for_clustering": summary["genes_used_for_clustering"],
        "clusters": summary["clusters"],
    }
    path.write_text("\n".join(f"{key}: {value}" for key, value in fields.items()) + "\n")


def main() -> None:
    """Run the Scanpy analysis."""
    args = parse_args()
    outdir = ensure_outdir(args.outdir)
    plots_dir = ensure_outdir(outdir / "plots")
    objects_dir = ensure_outdir(outdir / "objects")

    mt_prefix = default_mt_prefix(args.species, args.mt_prefix)
    sc.settings.figdir = str(plots_dir)

    adata = sc.read_10x_mtx(args.input, var_names="gene_symbols", cache=False)
    adata.var_names_make_unique()
    cells_before_qc = int(adata.n_obs)
    genes_before_qc = int(adata.n_vars)

    adata.var["mt"] = mitochondrial_gene_mask(adata.var_names, mt_prefix)
    sc.pp.calculate_qc_metrics(adata, qc_vars=["mt"], percent_top=None, log1p=False, inplace=True)
    adata.obs.to_csv(outdir / "cell_metadata_prefilter.csv")

    adata = adata[adata.obs["n_genes_by_counts"] > args.min_features, :].copy()
    adata = adata[adata.obs["n_genes_by_counts"] < args.max_features, :].copy()
    adata = adata[adata.obs["pct_counts_mt"] < args.max_mt, :].copy()
    if adata.n_obs == 0:
        raise ValueError("No cells remained after QC filtering. Relax thresholds or inspect input data.")
    if adata.n_obs < 3:
        raise ValueError("At least three cells are required after QC for neighbors and clustering.")
    if adata.n_vars < 2:
        raise ValueError("At least two genes are required after QC for dimensionality reduction.")

    sc.pp.normalize_total(adata, target_sum=1e4)
    sc.pp.log1p(adata)
    adata.raw = adata

    sc.pp.highly_variable_genes(adata, min_mean=0.0125, max_mean=3, min_disp=0.5)
    hvg_count = int(adata.var["highly_variable"].sum()) if "highly_variable" in adata.var else 0
    use_highly_variable = False
    if hvg_count >= 2:
        adata = adata[:, adata.var["highly_variable"]].copy()
        use_highly_variable = True

    sc.pp.scale(adata, max_value=10)
    n_pcs = min(40, max(1, min(adata.n_obs, adata.n_vars) - 1))
    sc.tl.pca(adata, svd_solver="arpack", n_comps=n_pcs, use_highly_variable=use_highly_variable)

    n_neighbors = min(10, adata.n_obs - 1)
    sc.pp.neighbors(adata, n_neighbors=n_neighbors, n_pcs=n_pcs)
    sc.tl.leiden(adata, resolution=args.cluster_resolution, key_added="leiden")
    sc.tl.umap(adata)

    cluster_count = int(adata.obs["leiden"].nunique())
    if cluster_count > 1:
        sc.tl.rank_genes_groups(adata, groupby="leiden", method="wilcoxon")
        markers = sc.get.rank_genes_groups_df(adata, group=None)
        sc.pl.rank_genes_groups(adata, n_genes=20, sharey=False, save=f"_{args.sample}.png", show=False)
    else:
        markers = pd.DataFrame(columns=["group", "names", "scores", "logfoldchanges", "pvals", "pvals_adj"])

    sc.pl.umap(adata, color=["leiden"], save=f"_{args.sample}_clusters.png", show=False)

    adata.obs.to_csv(outdir / "cell_metadata.csv")
    markers.to_csv(outdir / "cluster_markers.csv", index=False)

    canonical_h5ad = objects_dir / f"{args.sample}.h5ad"
    legacy_h5ad = outdir / f"{args.sample}_scanpy.h5ad"
    adata.write_h5ad(canonical_h5ad)
    shutil.copyfile(canonical_h5ad, legacy_h5ad)

    summary = {
        "contract_version": CONTRACT_VERSION,
        "engine": "scanpy",
        "sample": args.sample,
        "input_path": str(Path(args.input).resolve()),
        "species": args.species,
        "genome": args.genome,
        "mt_prefix": mt_prefix,
        "thresholds": {
            "min_features": args.min_features,
            "max_features": args.max_features,
            "max_mt": args.max_mt,
            "cluster_resolution": args.cluster_resolution,
        },
        "cells_before_qc": cells_before_qc,
        "genes_before_qc": genes_before_qc,
        "cells_after_qc": int(adata.n_obs),
        "genes_used_for_clustering": int(adata.n_vars),
        "clusters": cluster_count,
        "versions": {
            "python": sys.version.split()[0],
            "scanpy": package_version("scanpy"),
            "anndata": package_version("anndata"),
            "pandas": package_version("pandas"),
            "numpy": package_version("numpy"),
        },
    }
    write_json(summary, outdir / "run_summary.json")
    write_legacy_run_summary(summary, outdir / "run_summary.txt")
    write_output_manifest(outdir, args.sample, "scanpy")


if __name__ == "__main__":
    main()
