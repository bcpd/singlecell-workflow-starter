# Downstream Output Contract

Contract version: `1.0.0`

Each engine writes outputs under:

```text
<outdir>/<sample>/<engine>/
```

For direct script usage, pass the engine directory as `--outdir`.

## Required files

```text
cell_metadata_prefilter.csv
cell_metadata.csv
cluster_markers.csv
run_summary.json
output_manifest.json
plots/
objects/<sample>.h5ad   # Scanpy
objects/<sample>.rds    # Seurat
```

Legacy aliases may also be written for compatibility, but consumers should use the files above.

## `run_summary.json`

The summary is the canonical machine-readable run record. It includes:

- `contract_version`
- `engine`
- `sample`
- `input_path`
- `species`
- `genome`
- `mt_prefix`
- `thresholds`
- `cells_before_qc`
- `genes_before_qc`
- `cells_after_qc`
- `genes_used_for_clustering`
- `clusters`
- `versions`

## `output_manifest.json`

The manifest records the required contract files and whether each exists at write time. CI and downstream automation should validate this file before consuming analysis outputs.

## Samplesheet input

The canonical workflow input is a CSV with required columns:

```csv
sample,matrix_dir
```

Optional columns:

```csv
species,genome,mt_prefix
```

Defaults:

- `species`: `human`
- human mitochondrial prefix: `MT-`
- mouse mitochondrial prefix: `mt-`
- `genome`: empty string
