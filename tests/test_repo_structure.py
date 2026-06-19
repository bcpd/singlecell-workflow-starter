"""Repository structure tests."""

from __future__ import annotations

from pathlib import Path


def test_expected_entry_points_exist():
    """The main workflow and key scripts should exist."""
    expected = [
        "main.nf",
        "nextflow.config",
        "docs/output_contract.md",
        "containers/scanpy.Dockerfile",
        "containers/seurat.Dockerfile",
        "data/samplesheets/downstream_samplesheet.csv.example",
        "R/01_seurat_pbmc_qc_cluster.R",
        "python/01_scanpy_pbmc_qc_cluster.py",
        "python/02_celltypist_annotation.py",
        "python/03_scanpy_paga_paul15.py",
        "scripts/generate_conda_locks.sh",
    ]

    for path in expected:
        assert Path(path).exists(), f"Missing expected file: {path}"
