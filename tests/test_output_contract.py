"""Tests for the downstream output contract."""

from __future__ import annotations

import json
from pathlib import Path

from python.utils import CONTRACT_VERSION, required_contract_paths, write_output_manifest


def test_required_contract_paths_include_engine_object():
    """Each engine should advertise the expected canonical object path."""
    assert "objects/demo.h5ad" in required_contract_paths("demo", "scanpy")
    assert "objects/demo.rds" in required_contract_paths("demo", "seurat")


def test_write_output_manifest_records_required_files(tmp_path):
    """Output manifests should be machine-readable and contract-versioned."""
    outdir = tmp_path / "demo" / "scanpy"
    (outdir / "plots").mkdir(parents=True)
    (outdir / "objects").mkdir()
    for name in ["cell_metadata_prefilter.csv", "cell_metadata.csv", "cluster_markers.csv", "run_summary.json"]:
        (outdir / name).write_text("stub\n")
    (outdir / "objects" / "demo.h5ad").write_text("stub\n")

    manifest = write_output_manifest(outdir, "demo", "scanpy")

    manifest_path = outdir / "output_manifest.json"
    assert manifest_path.exists()
    reloaded = json.loads(manifest_path.read_text())
    assert reloaded == manifest
    assert reloaded["contract_version"] == CONTRACT_VERSION
    assert all(file_record["exists"] for file_record in reloaded["files"])


def test_tiny_10x_fixture_has_expected_files():
    """The smoke-test fixture should look like a filtered 10x matrix directory."""
    fixture = Path("tests/fixtures/tiny_10x")
    assert (fixture / "matrix.mtx.gz").exists()
    assert (fixture / "barcodes.tsv.gz").exists()
    assert (fixture / "features.tsv.gz").exists()
