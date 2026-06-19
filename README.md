# Single-cell workflows starter

This repository is a reusable downstream scRNA-seq starter for existing 10x filtered matrices. It keeps Seurat and Scanpy as first-class analysis engines with aligned output contracts, reproducible environments, lightweight tests, and a small Nextflow orchestration layer.

Raw FASTQ-to-count generation is intentionally out of scope for the local workflow. Use nf-core/scrnaseq or Cell Ranger upstream, then pass the resulting filtered matrix directories into this starter.

## Gap this fills

Many single-cell examples show either a one-off notebook or a full FASTQ-to-count production pipeline. This starter focuses on the middle layer: taking existing count matrices and turning them into reproducible downstream analysis outputs that are easy to test, compare, and hand off.

It is meant to provide:

- A small, auditable Nextflow wrapper around Seurat and Scanpy analyses.
- A shared input contract for one or more 10x matrix directories.
- Stable output files across engines, including metadata, marker tables, objects, plots, run summaries, and manifests.
- CI-friendly smoke tests using a tiny deterministic 10x fixture.
- Clear boundaries with upstream count-generation tools instead of reimplementing nf-core/scrnaseq or Cell Ranger.

## Repository layout

```text
.
├── main.nf                         # Downstream Nextflow workflow
├── nextflow.config                 # Default workflow parameters
├── conf/docker.config              # Project container profile
├── containers/                     # Docker build recipes for workflow engines
├── data/samplesheets/              # Example input samplesheets
├── docs/output_contract.md         # Stable output contract
├── scripts/                        # Data download and reproducibility helpers
├── R/                              # Seurat modules
├── python/                         # Scanpy modules and shared utilities
├── envs/                           # Conda environment specs
└── tests/                          # Unit tests and tiny 10x fixture
```

## Quick start

Use Nextflow 26.0.0 or newer for this workflow:

```bash
nextflow -version
```

Create the Python and R environments:

```bash
micromamba create -n singlecell-python -f envs/scanpy.yml
micromamba create -n singlecell-r -f envs/seurat.yml
```

Download the PBMC 3k example matrix with checksum verification:

```bash
bash scripts/download_pbmc3k.sh
```

Create or edit a downstream samplesheet:

```csv
sample,matrix_dir,species,genome,mt_prefix
pbmc3k,data/raw/pbmc3k/filtered_gene_bc_matrices/hg19,human,hg19,MT-
```

Run both engines through Nextflow:

```bash
nextflow run main.nf \
  --samplesheet data/samplesheets/downstream_samplesheet.csv.example \
  --outdir results/local_nextflow \
  -profile conda
```

The `conda` profile uses `micromamba` through Nextflow's `conda.useMicromamba` setting. First use requires network access to solve and create process environments under `work/conda`.

The single-sample compatibility path is still available:

```bash
nextflow run main.nf \
  --matrix_dir data/raw/pbmc3k/filtered_gene_bc_matrices/hg19 \
  --sample pbmc3k \
  --species human \
  --genome hg19 \
  --outdir results/local_nextflow \
  -profile conda
```

## Direct script usage

Run Scanpy directly:

```bash
python python/01_scanpy_pbmc_qc_cluster.py \
  --input data/raw/pbmc3k/filtered_gene_bc_matrices/hg19 \
  --outdir results/pbmc3k/scanpy \
  --sample pbmc3k \
  --species human \
  --genome hg19
```

Run Seurat directly:

```bash
Rscript R/01_seurat_pbmc_qc_cluster.R \
  --input data/raw/pbmc3k/filtered_gene_bc_matrices/hg19 \
  --outdir results/pbmc3k/seurat \
  --sample pbmc3k \
  --species human \
  --genome hg19
```

Each engine writes the stable contract documented in `docs/output_contract.md`, including `run_summary.json` and `output_manifest.json`.

## Containers and lockfiles

Build project containers before using `-profile docker`:

```bash
docker build -f containers/scanpy.Dockerfile -t single-cell-workflows-starter-scanpy:0.1.0 .
docker build -f containers/seurat.Dockerfile -t single-cell-workflows-starter-seurat:0.1.0 .
```

Generate conda lockfiles when `conda-lock` is available:

```bash
bash scripts/generate_conda_locks.sh
```

The lock script targets `linux-64` and `osx-arm64`.

## Upstream count generation

For production FASTQ-to-count processing, prefer nf-core/scrnaseq:

```bash
bash scripts/run_nfcore_scrnaseq_example.sh
```

The Cell Ranger shell script is only an example command wrapper because Cell Ranger licensing and installation are project-specific.

## Tests

Run lightweight tests:

```bash
pytest
```

The test suite includes unit tests for shared utilities and contract checks against a deterministic tiny 10x fixture in `tests/fixtures/tiny_10x/`.

## Data policy

Do not commit raw FASTQ files, large `.h5ad` files, large `.rds` files, or generated result directories. Commit scripts, configs, small fixtures, summary tables, documentation, and reproducibility metadata.
