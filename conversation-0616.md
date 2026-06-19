# Review repository architecture

> Review and explain this repository as if I am a new senior developer joining the project.
>
> Do not edit files.
>
> Start by building a mental model of the repo from README, dependency files, config files, tests, scripts, and entry points.
>
> Return:
> 1. plain-English purpose
> 2. architecture overview
> 3. main execution paths
> 4. key modules and responsibilities
> 5. data inputs and outputs
> 6. dependencies and runtime assumptions
> 7. how to run and test it
> 8. highest-risk areas
> 9. missing tests or documentation
> 10. recommended next questions
>
> Cite file paths and functions for every important claim.
> Distinguish facts from guesses.
> Prioritize correctness, reproducibility, maintainability, and security over style comments.

<details><summary>11 previous messages</summary>

> I’ll read the repository first and keep it read-only. I’m going to map the entry points, config, tests, and scripts before summarizing so the explanation is grounded in actual files.
>
> The file list is small and there’s no usable Git metadata at the workspace root, so I’m treating the working tree as a plain source snapshot. Next I’m reading the workflow, Python/R scripts, tests, and dependency manifests with line numbers so the final notes can cite concrete locations.
>
> The stated scope is a portfolio/starter scRNA-seq repo rather than a production pipeline. The Nextflow path is deliberately downstream-only from an existing filtered 10x matrix, while raw FASTQ handling is delegated to Cell Ranger or nf-core scripts.
>
> The Python layer has one reusable utility file and several standalone command-line scripts. I’m now checking the R scripts and the shell/bin entry points to see how much of the README’s workflow is actually executable versus illustrative.
>
> The tests are lightweight structure and utility tests only; they do not exercise the heavy biological workflows. I’m going to run pytest with its cache disabled so this stays read-only in the repo.
>
> `python` is not on PATH in this shell, so I’m checking with `python3` before treating the test suite as unverified.
>
> The system Python does not have pytest installed. I’m checking the bundled workspace runtimes next; if they include pytest/pandas I can still run the lightweight tests without installing anything.
>
> There is a bundled Python available, so I’m using that for the repository’s lightweight tests. This still does not install dependencies or modify source files.
>
> The bundled Python also lacks pytest, so I’ll report the test suite as not runnable in the current shell without creating the declared environment. I’m doing one final pass over directory state and hidden/config files before writing the review.
>
> There is a GitHub Actions workflow, but it only installs pandas/numpy/pytest and runs the lightweight tests. I’m checking whether any real data artifacts are present; that affects the reproducibility story.
>
> No real input data or generated results are checked in, only examples and placeholders. I have enough evidence now; I’ll synthesize the repo model and call out the specific places where behavior is factual versus inferred.
</details>

I did not edit files.

**1. Purpose**
Fact: this is a small, portfolio-oriented scRNA-seq starter repo, not a production workflow replacement. The README says it demonstrates Cell Ranger/nf-core count generation, Seurat QC/clustering/integration/reference mapping, Scanpy QC/clustering/annotation/trajectory, and reproducible scripts/tests/Nextflow orchestration [README.md](./README.md:3), and explicitly says it is not meant to replace nf-core/scrnaseq [README.md](./README.md:11).

**2. Architecture**
Fact: the repo is script-first, with a thin Nextflow wrapper. `main.nf` defines two DSL2 processes, `RUN_SEURAT` and `RUN_SCANPY`, both consuming one 10x matrix channel [main.nf](./main.nf:21). Defaults live in `nextflow.config` [nextflow.config](./nextflow.config:6). Python shared helpers are in `python/utils.py`, especially `ensure_outdir`, `mitochondrial_gene_mask`, and `write_dataframe` [utils.py](./python/utils.py:12). R and Python analyses are otherwise standalone CLIs with `parse_args()` / `main()` in Python scripts [01_scanpy_pbmc_qc_cluster.py](./python/01_scanpy_pbmc_qc_cluster.py:24).

Guess: the intended “canonical” demo path is PBMC 3k matrix download, then parallel Seurat/Scanpy downstream analysis, because the README quick start and `main.nf` both center that path [README.md](./README.md:56).

**3. Main Execution Paths**
Fact: PBMC 3k data is downloaded by `scripts/download_pbmc3k.sh` from 10x with `curl`, then extracted under `data/raw/pbmc3k` [download_pbmc3k.sh](./scripts/download_pbmc3k.sh:8).

Fact: Seurat PBMC analysis reads a 10x matrix with `Read10X`, creates a Seurat object, filters, normalizes, clusters, runs UMAP, finds markers, and writes plots/tables/RDS [01_seurat_pbmc_qc_cluster.R](./R/01_seurat_pbmc_qc_cluster.R:36).

Fact: Scanpy PBMC analysis reads a 10x matrix with `sc.read_10x_mtx`, filters by gene/mitochondrial thresholds, normalizes/logs, selects HVGs, PCA/neighbors/Leiden/UMAP, ranks markers, and writes CSV/PNG/H5AD outputs in `main()` [01_scanpy_pbmc_qc_cluster.py](./python/01_scanpy_pbmc_qc_cluster.py:36).

Fact: CellTypist annotation consumes an existing `.h5ad`, downloads/loads a CellTypist model, writes prediction CSV and annotated H5AD in `main()` [02_celltypist_annotation.py](./python/02_celltypist_annotation.py:29).

Fact: additional demos cover Seurat `pbmcsca` integration [02_seurat_integration_pbmcsca.R](./R/02_seurat_integration_pbmcsca.R:22), Seurat `panc8` label transfer [03_seurat_label_transfer_panc8.R](./R/03_seurat_label_transfer_panc8.R:20), Scanpy `paul15` PAGA/DPT [03_scanpy_paga_paul15.py](./python/03_scanpy_paga_paul15.py:30), and an scVI scaffold [04_integration_scvi_placeholder.py](./python/04_integration_scvi_placeholder.py:25).

**4. Key Modules**
Fact: `main.nf` is orchestration only: `RUN_SEURAT` shells out to `R/01_seurat_pbmc_qc_cluster.R`, and `RUN_SCANPY` shells out to `python/01_scanpy_pbmc_qc_cluster.py` [main.nf](./main.nf:26).

Fact: `bin/make_cellranger_samplesheet.py::main()` scans one FASTQ directory per sample and writes a Cell Ranger-style CSV [make_cellranger_samplesheet.py](./bin/make_cellranger_samplesheet.py:27).

Fact: `tests/test_scanpy_utils.py` tests only the small Python utility functions [test_scanpy_utils.py](./tests/test_scanpy_utils.py:10), and `tests/test_repo_structure.py` checks that expected entry-point files exist [test_repo_structure.py](./tests/test_repo_structure.py:8).

**5. Data Inputs / Outputs**
Fact: primary input is a Cell Ranger/10x filtered matrix directory containing matrix/barcode/features files, as documented in `nextflow.config` [nextflow.config](./nextflow.config:7). Example samplesheets cover matrix input and Cell Ranger FASTQ metadata [pbmc3k_matrix.csv.example](./data/samplesheets/pbmc3k_matrix.csv.example:1), [pbmc1k_cellranger.csv.example](./data/samplesheets/pbmc1k_cellranger.csv.example:1).

Fact: outputs include marker CSVs, cell metadata CSVs, run summaries, PNG plots, Seurat `.rds`, and Scanpy `.h5ad` files [01_seurat_pbmc_qc_cluster.R](./R/01_seurat_pbmc_qc_cluster.R:94), [01_scanpy_pbmc_qc_cluster.py](./python/01_scanpy_pbmc_qc_cluster.py:85). Large outputs are intentionally gitignored [gitignore](./.gitignore:1).

**6. Dependencies / Runtime Assumptions**
Fact: Python environment targets Python 3.11 plus Scanpy, AnnData, pandas, numpy, scipy, matplotlib, scikit-learn, Leiden/igraph/louvain, pytest, and CellTypist [scanpy.yml](./envs/scanpy.yml:1).

Fact: R conda env targets R 4.4 and some R/Bioconductor basics, but does not list Seurat or SeuratData [seurat.yml](./envs/seurat.yml:1). Separate installer script installs Seurat from CRAN and SeuratData from GitHub [install_r_packages.R](./envs/install_r_packages.R:18).

Fact: several paths require network on first use: 10x download via `curl`, R package install via CRAN/GitHub/Bioconductor, SeuratData `InstallData`, CellTypist model download, and possibly Scanpy dataset download [download_pbmc3k.sh](./scripts/download_pbmc3k.sh:16), [02_celltypist_annotation.py](./python/02_celltypist_annotation.py:37).

**7. How To Run / Test**
Run after creating environments:
```bash
micromamba create -n singlecell-python -f envs/scanpy.yml
micromamba create -n singlecell-r -f envs/seurat.yml
Rscript envs/install_r_packages.R
bash scripts/download_pbmc3k.sh
python python/01_scanpy_pbmc_qc_cluster.py --input data/raw/pbmc3k/filtered_gene_bc_matrices/hg19 --outdir results/scanpy_pbmc3k --project pbmc3k
Rscript R/01_seurat_pbmc_qc_cluster.R --input data/raw/pbmc3k/filtered_gene_bc_matrices/hg19 --outdir results/seurat_pbmc3k --project pbmc3k
nextflow run main.nf --matrix_dir data/raw/pbmc3k/filtered_gene_bc_matrices/hg19 --sample pbmc3k --outdir results/local_nextflow -profile conda
pytest
```
Fact: CI installs only pandas/numpy/pytest, then runs `pytest`; it does not install Scanpy, Seurat, Nextflow, or run workflow smoke tests [tests.yml](./.github/workflows/tests.yml:20). I tried running tests locally, but `python` is absent and both available `python3` interpreters lack `pytest`, so I could not execute them without installing dependencies.

**8. Highest-Risk Areas**
Fact: dependency reproducibility is weak: most conda packages are unpinned, R installation pulls current CRAN/GitHub/Bioconductor packages, and no lockfile is present [scanpy.yml](./envs/scanpy.yml:5), [install_r_packages.R](./envs/install_r_packages.R:12).

Fact: `main.nf` exposes `params.run_cellranger`, but there is no Cell Ranger process; the workflow still builds `ch_matrix` from `params.matrix_dir` [main.nf](./main.nf:16). That flag is misleading.

Fact: Docker profile uses generic base images, not custom images with all R/Python packages preinstalled [docker.config](./conf/docker.config:7). Guess: `-profile docker` is unlikely to be sufficient for reproducible execution without additional setup.

Fact: QC logic is tutorial-style and human-specific: mitochondrial genes are hardcoded as `MT-`, and default filters are fixed thresholds [01_seurat_pbmc_qc_cluster.R](./R/01_seurat_pbmc_qc_cluster.R:47), [01_scanpy_pbmc_qc_cluster.py](./python/01_scanpy_pbmc_qc_cluster.py:30).

Fact: external downloads have no checksum or version pinning, which affects reproducibility and supply-chain confidence [download_pbmc3k.sh](./scripts/download_pbmc3k.sh:16).

**9. Missing Tests / Docs**
Missing: CLI smoke tests for Scanpy, CellTypist with a tiny fixture, R scripts, and `main.nf`; current tests only cover utilities and file existence [test_scanpy_utils.py](./tests/test_scanpy_utils.py:10).

Missing: documented expected output contract per workflow; README says to add a `results/README.md`, but only `.gitkeep` placeholders are present [README.md](./README.md:116).

Missing: an actual nf-core samplesheet matching `scripts/run_nfcore_scrnaseq_example.sh`, which references `data/samplesheets/nfcore_scrnaseq_samplesheet.csv` but only two different example samplesheets exist [run_nfcore_scrnaseq_example.sh](./scripts/run_nfcore_scrnaseq_example.sh:10).

**10. Recommended Next Questions**
1. Is this meant to stay portfolio/demo-only, or become a reusable production starter?
2. Which path should be canonical: raw FASTQ via nf-core, raw FASTQ via Cell Ranger, or downstream-only from filtered matrices?
3. What species, chemistry, and assay assumptions should be supported beyond human 10x GEX?
4. Should environments be locked and containerized for exact reproducibility?
5. What minimal fixture dataset should CI use for end-to-end smoke tests?
6. What outputs are considered the stable contract: plots, metadata, markers, H5AD/RDS, reports, or all of them?

> 1. reusable production starter
> 2. not sure; suggest
> 3. not sure; suggest
> 4. yes
> 5. not sure
> 6. all of them

Given those answers, I’d steer the repo toward a **production starter that delegates raw count generation and owns downstream analysis quality**.

**Recommended Decisions**

1. **Canonical execution path**
Use **nf-core/scrnaseq as the preferred raw FASTQ to counts path**, not a custom Cell Ranger wrapper. The repo already says nf-core is the production-style alternative [README.md](./README.md:92), and `conf/docker.config` notes Cell Ranger licensing/install constraints [docker.config](./conf/docker.config:3).

Keep local `main.nf` focused on downstream analysis from standardized count inputs: 10x matrix, `.h5ad`, or `.rds`.

2. **Supported biological scope**
Start with:
- human and mouse
- 10x Genomics single-cell gene expression
- filtered feature-barcode matrices as the stable input
- configurable species metadata: genome, mitochondrial gene prefix, reference path, expected chemistry

Reason: current code assumes human-style `MT-` mitochondrial genes in both Seurat and Scanpy paths [01_seurat_pbmc_qc_cluster.R](./R/01_seurat_pbmc_qc_cluster.R:47), [01_scanpy_pbmc_qc_cluster.py](./python/01_scanpy_pbmc_qc_cluster.py:49). Productionizing should make that explicit rather than implicit.

3. **Output contract**
Since you want all outputs stable, define a versioned output contract for:
- `cell_metadata.csv`
- `cluster_markers.csv`
- `run_summary.{csv,txt,json}`
- UMAP/QC/marker plots
- final `.h5ad`
- final `.rds`
- optional annotation outputs
- optional trajectory outputs

Right now those outputs exist, but their schemas are informal [01_scanpy_pbmc_qc_cluster.py](./python/01_scanpy_pbmc_qc_cluster.py:85), [01_seurat_pbmc_qc_cluster.R](./R/01_seurat_pbmc_qc_cluster.R:94).

4. **Reproducibility**
Yes to locked environments. I’d add:
- `conda-lock` files for Python/R environments
- pinned Docker/Singularity containers
- pinned package versions
- checksum validation for downloaded demo data
- explicit versions in run summaries
- CI that proves the lockfiles still solve

Current envs are useful but too floating for production starter use [scanpy.yml](./envs/scanpy.yml:5), [install_r_packages.R](./envs/install_r_packages.R:18).

5. **Minimal fixture dataset**
Use a tiny synthetic 10x matrix checked into `tests/fixtures/`, not PBMC3k. It should be small enough for CI and include:
- `matrix.mtx.gz`
- `barcodes.tsv.gz`
- `features.tsv.gz`
- 20-100 cells
- 50-200 genes
- a few `MT-` / `mt-` genes

That enables CLI smoke tests for `python/01_scanpy_pbmc_qc_cluster.py::main()` and ideally a lightweight R smoke test. Current tests only validate utilities and file presence [test_scanpy_utils.py](./tests/test_scanpy_utils.py:10), [test_repo_structure.py](./tests/test_repo_structure.py:8).

**Suggested Direction**
The clean product shape is:

`sample manifest -> nf-core/scrnaseq or external count source -> standardized 10x/H5AD/RDS input -> QC -> clustering -> annotation -> integration/trajectory optional modules -> versioned outputs`

I would treat `main.nf` as the stable production entry point, remove or implement the misleading `run_cellranger` flag, and add tests around every declared output. That gets the repo from “portfolio scripts” to “reusable starter with contracts.”

> how to proceed

<details><summary>6 previous messages</summary>

> I’ll turn the review into an implementation path. First I’m doing a quick read-only check of the current entry points and test/config surface so the plan maps to the repo as it exists now.
>
> <details><summary>Explored a search, a list</summary>
>
> - Listed files
> - Searched for `run_cellranger|matrix_dir|outdir|sample|pytest|scanpy|Seurat|celltypist|conda|docker` in `README.md`
>
> </details>
>
> The remaining choices are product-level, not things I can infer from files. I’ll ask only the decisions that materially change the implementation plan.
>
> User input response
>
> - What should the first implementation milestone optimize for?
>   - Core downstream (Recommended)
> - Which downstream analysis posture should the production starter use?
>   - Seurat + Scanpy (Recommended)
> - What CI fixture strategy should we plan around?
>   - Tiny synthetic 10x (Recommended)
>
> Plan
>
> # Productionize Core Downstream scRNA-seq Starter
>
> ## Summary
> - First milestone: productionize the downstream workflow from existing 10x filtered matrices; keep raw FASTQ processing delegated to nf-core/scrnaseq documentation/examples.
> - Keep **Seurat and Scanpy as first-class paths** with aligned output contracts, not numerically identical results.
> - Support human and mouse 10x GEX inputs with configurable mitochondrial gene prefix and QC thresholds.
> - Make reproducibility explicit through locked environments, pinned containers, deterministic fixtures, and CI smoke tests.
>
> ## Key Changes
> - Update [main.nf](/Users/pedrodimitriu/repos/single-cell-workflows-starter/main.nf) to use a canonical samplesheet input:
>   - Required columns: `sample`, `matrix_dir`.
>   - Optional columns: `species`, `genome`, `mt_prefix`.
>   - Defaults: `species=human`, `mt_prefix=MT-`; mouse default is `mt-`.
>   - Keep `--matrix_dir` + `--sample` as single-sample compatibility input.
>   - Remove the misleading `--run_cellranger` behavior from the local workflow.
> - Standardize the output contract under `<outdir>/<sample>/<engine>/`:
>   - `cell_metadata_prefilter.csv`
>   - `cell_metadata.csv`
>   - `cluster_markers.csv`
>   - `run_summary.json`
>   - `output_manifest.json`
>   - `plots/`
>   - `objects/<sample>.h5ad` for Scanpy and `objects/<sample>.rds` for Seurat.
> - Update the Seurat and Scanpy CLIs to accept the same production parameters:
>   - `--sample`, `--input`, `--outdir`, `--species`, `--mt-prefix`, `--min-features`, `--max-features`, `--max-mt`, `--cluster-resolution`.
>   - Include package versions, input path, thresholds, cell/gene counts, cluster count, and contract version in `run_summary.json`.
> - Add reproducibility assets:
>   - Generate and commit `conda-lock` files for Linux and macOS ARM where practical.
>   - Replace generic Docker profile images with project-specific pinned images built from the locked environments.
>   - Add checksum validation to public demo data downloads.
> - Update docs:
>   - Rewrite the README quick start around samplesheet-driven downstream analysis.
>   - Add an output contract document.
>   - Keep Cell Ranger and nf-core as documented upstream count-generation options, not local production code.
>
> ## Test Plan
> - Add a tiny deterministic 10x fixture checked into `tests/fixtures/tiny_10x/` with `matrix.mtx.gz`, `barcodes.tsv.gz`, and `features.tsv.gz`.
> - Add tests for samplesheet validation, species/mitochondrial-prefix defaults, output manifest generation, and output schema checks.
> - Add Scanpy integration CI using the fixture and locked Python environment.
> - Add Seurat integration CI using the fixture and locked R environment.
> - Add a Nextflow smoke test that runs both engines against the fixture and asserts the full output contract exists.
> - Keep lightweight utility tests for fast feedback on every PR.
>
> ## Assumptions
> - Raw FASTQ-to-count generation is out of scope for milestone 1 except documentation and nf-core example cleanup.
> - The stable public interface is the samplesheet plus output contract, not internal script implementation details.
> - Cross-engine parity means equivalent files and biological workflow stages; exact cluster assignments or marker rankings are not required to match.
> - All current outputs remain supported, but `run_summary.json` and `output_manifest.json` become the canonical machine-readable artifacts.
>
> Plan implementation
>
> Status: completed
> # Productionize Core Downstream scRNA-seq Starter
>
> ## Summary
> - First milestone: productionize the downstream workflow from existing 10x filtered matrices; keep raw FASTQ processing delegated to nf-core/scrnaseq documentation/examples.
> - Keep **Seurat and Scanpy as first-class paths** with aligned output contracts, not numerically identical results.
> - Support human and mouse 10x GEX inputs with configurable mitochondrial gene prefix and QC thresholds.
> - Make reproducibility explicit through locked environments, pinned containers, deterministic fixtures, and CI smoke tests.
>
> ## Key Changes
> - Update [main.nf](/Users/pedrodimitriu/repos/single-cell-workflows-starter/main.nf) to use a canonical samplesheet input:
>   - Required columns: `sample`, `matrix_dir`.
>   - Optional columns: `species`, `genome`, `mt_prefix`.
>   - Defaults: `species=human`, `mt_prefix=MT-`; mouse default is `mt-`.
>   - Keep `--matrix_dir` + `--sample` as single-sample compatibility input.
>   - Remove the misleading `--run_cellranger` behavior from the local workflow.
> - Standardize the output contract under `<outdir>/<sample>/<engine>/`:
>   - `cell_metadata_prefilter.csv`
>   - `cell_metadata.csv`
>   - `cluster_markers.csv`
>   - `run_summary.json`
>   - `output_manifest.json`
>   - `plots/`
>   - `objects/<sample>.h5ad` for Scanpy and `objects/<sample>.rds` for Seurat.
> - Update the Seurat and Scanpy CLIs to accept the same production parameters:
>   - `--sample`, `--input`, `--outdir`, `--species`, `--mt-prefix`, `--min-features`, `--max-features`, `--max-mt`, `--cluster-resolution`.
>   - Include package versions, input path, thresholds, cell/gene counts, cluster count, and contract version in `run_summary.json`.
> - Add reproducibility assets:
>   - Generate and commit `conda-lock` files for Linux and macOS ARM where practical.
>   - Replace generic Docker profile images with project-specific pinned images built from the locked environments.
>   - Add checksum validation to public demo data downloads.
> - Update docs:
>   - Rewrite the README quick start around samplesheet-driven downstream analysis.
>   - Add an output contract document.
>   - Keep Cell Ranger and nf-core as documented upstream count-generation options, not local production code.
>
> ## Test Plan
> - Add a tiny deterministic 10x fixture checked into `tests/fixtures/tiny_10x/` with `matrix.mtx.gz`, `barcodes.tsv.gz`, and `features.tsv.gz`.
> - Add tests for samplesheet validation, species/mitochondrial-prefix defaults, output manifest generation, and output schema checks.
> - Add Scanpy integration CI using the fixture and locked Python environment.
> - Add Seurat integration CI using the fixture and locked R environment.
> - Add a Nextflow smoke test that runs both engines against the fixture and asserts the full output contract exists.
> - Keep lightweight utility tests for fast feedback on every PR.
>
> ## Assumptions
> - Raw FASTQ-to-count generation is out of scope for milestone 1 except documentation and nf-core example cleanup.
> - The stable public interface is the samplesheet plus output contract, not internal script implementation details.
> - Cross-engine parity means equivalent files and biological workflow stages; exact cluster assignments or marker rankings are not required to match.
> - All current outputs remain supported, but `run_summary.json` and `output_manifest.json` become the canonical machine-readable artifacts.
</details>

> PLEASE IMPLEMENT THIS PLAN:
> # Productionize Core Downstream scRNA-seq Starter
>
> ## Summary
> - First milestone: productionize the downstream workflow from existing 10x filtered matrices; keep raw FASTQ processing delegated to nf-core/scrnaseq documentation/examples.
> - Keep **Seurat and Scanpy as first-class paths** with aligned output contracts, not numerically identical results.
> - Support human and mouse 10x GEX inputs with configurable mitochondrial gene prefix and QC thresholds.
> - Make reproducibility explicit through locked environments, pinned containers, deterministic fixtures, and CI smoke tests.
>
> ## Key Changes
> - Update [main.nf](./main.nf) to use a canonical samplesheet input:
>   - Required columns: `sample`, `matrix_dir`.
>   - Optional columns: `species`, `genome`, `mt_prefix`.
>   - Defaults: `species=human`, `mt_prefix=MT-`; mouse default is `mt-`.
>   - Keep `--matrix_dir` + `--sample` as single-sample compatibility input.
>   - Remove the misleading `--run_cellranger` behavior from the local workflow.
> - Standardize the output contract under `<outdir>/<sample>/<engine>/`:
>   - `cell_metadata_prefilter.csv`
>   - `cell_metadata.csv`
>   - `cluster_markers.csv`
>   - `run_summary.json`
>   - `output_manifest.json`
>   - `plots/`
>   - `objects/<sample>.h5ad` for Scanpy and `objects/<sample>.rds` for Seurat.
> - Update the Seurat and Scanpy CLIs to accept the same production parameters:
>   - `--sample`, `--input`, `--outdir`, `--species`, `--mt-prefix`, `--min-features`, `--max-features`, `--max-mt`, `--cluster-resolution`.
>   - Include package versions, input path, thresholds, cell/gene counts, cluster count, and contract version in `run_summary.json`.
> - Add reproducibility assets:
>   - Generate and commit `conda-lock` files for Linux and macOS ARM where practical.
>   - Replace generic Docker profile images with project-specific pinned images built from the locked environments.
>   - Add checksum validation to public demo data downloads.
> - Update docs:
>   - Rewrite the README quick start around samplesheet-driven downstream analysis.
>   - Add an output contract document.
>   - Keep Cell Ranger and nf-core as documented upstream count-generation options, not local production code.
>
> ## Test Plan
> - Add a tiny deterministic 10x fixture checked into `tests/fixtures/tiny_10x/` with `matrix.mtx.gz`, `barcodes.tsv.gz`, and `features.tsv.gz`.
> - Add tests for samplesheet validation, species/mitochondrial-prefix defaults, output manifest generation, and output schema checks.
> - Add Scanpy integration CI using the fixture and locked Python environment.
> - Add Seurat integration CI using the fixture and locked R environment.
> - Add a Nextflow smoke test that runs both engines against the fixture and asserts the full output contract exists.
> - Keep lightweight utility tests for fast feedback on every PR.
>
> ## Assumptions
> - Raw FASTQ-to-count generation is out of scope for milestone 1 except documentation and nf-core example cleanup.
> - The stable public interface is the samplesheet plus output contract, not internal script implementation details.
> - Cross-engine parity means equivalent files and biological workflow stages; exact cluster assignments or marker rankings are not required to match.
> - All current outputs remain supported, but `run_summary.json` and `output_manifest.json` become the canonical machine-readable artifacts.

<details><summary>95 previous messages</summary>

> I’ll implement this as a scoped productionization pass rather than a rewrite of every analysis script. First I’m checking the available local tools so I can decide which verification and lock-generation steps are actually feasible in this environment.
>
> <details><summary>Ran 5 commands</summary>
>
> - Ran `which Rscript`
> - Ran `which micromamba`
> - Ran `which nextflow`
> - Ran `which conda-lock`
> - Ran `which python3`
>
> </details>
>
> `conda-lock` is not installed, but Nextflow, micromamba, Rscript, and python3 are present. I’ll add the lockfile generation contract and pinned container references, and I’ll run only checks that don’t require downloading new environments unless the local stack already supports them.
>
> <details><summary>Explored 5 files</summary>
>
> - Read `./main.nf`
> - Read `./python/utils.py`
> - Read `./nextflow.config`
> - Read `./python/01_scanpy_pbmc_qc_cluster.py`
> - Read `./R/01_seurat_pbmc_qc_cluster.R`
>
> </details>
>
> I’m going to make the local Nextflow entry point samplesheet-aware, then align the two core scripts around the same parameters and output layout. I’ll keep backwards-compatible aliases where they’re cheap so the existing README commands don’t break abruptly.
>
> I’m also going to add small shared helpers for contract metadata and samplesheet normalization. That lets the CLI scripts and tests agree on the same required files without duplicating schema details.
>
> I’m editing `python/utils.py` first to define the production contract version, samplesheet normalization, species defaults, JSON writing, and manifest generation. This is the low-risk base for both the workflow and tests.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `./python/utils.py` (+103 -1)
>
> </details>
>
> Next I’m updating Nextflow so it accepts either a canonical samplesheet or the old single-sample flags, and so each engine publishes into `<outdir>/<sample>/<engine>/`.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `./main.nf` (+83 -26)
> - Wrote `./main.nf` (+6 -6)
>
> </details>
>
> I’m updating `nextflow.config` to match the new interface: samplesheet first, single-sample compatibility second, and explicit QC/metadata defaults.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `./nextflow.config` (+17 -10)
>
> </details>
>
> Now I’m aligning the Scanpy CLI. The main changes are shared parameter names, adaptive small-fixture behavior, contract directories, JSON summary, and a manifest while keeping legacy output aliases.
>
> <details><summary>Deleted a file</summary>
>
> - Deleted `./python/01_scanpy_pbmc_qc_cluster.py` (+0 -104)
>
> </details>
>
> I removed the old Scanpy script body so I can replace it cleanly with the productionized version rather than stacking compatibility branches onto the tutorial script.
>
> <details><summary>Created a file</summary>
>
> - Wrote `./python/01_scanpy_pbmc_qc_cluster.py` (+175 -0)
>
> </details>
>
> I’m doing the same for the Seurat CLI: shared parameters, explicit mitochondrial prefix handling, canonical object/plot directories, JSON summary, and output manifest while preserving the legacy CSV/RDS outputs.
>
> <details><summary>Deleted a file</summary>
>
> - Deleted `./R/01_seurat_pbmc_qc_cluster.R` (+0 -110)
>
> </details>
>
> The old Seurat tutorial body is replaced as a unit so the final script has one clear production path plus backward-compatible argument aliases.
>
> <details><summary>Created a file</summary>
>
> - Wrote `./R/01_seurat_pbmc_qc_cluster.R` (+233 -0)
>
> </details>
>
> I’m updating the environment specs to include the new runtime dependency (`jsonlite`) and to make the core Seurat dependency explicit in the conda environment instead of relying only on the installer script.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `./envs/seurat.yml` (+2 -0)
>
> </details>
>
> The R installer script also needs to know about `jsonlite` for users who install packages outside conda.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `./envs/install_r_packages.R` (+1 -0)
>
> </details>
>
> For container reproducibility I’m replacing the generic base-image profile with project-specific image tags and adding Dockerfile recipes so users can build the exact images used by the Docker profile.
>
> <details><summary>Created a file, edited a file</summary>
>
> - Wrote `./conf/docker.config` (+4 -3)
> - Wrote `./containers/scanpy.Dockerfile` (+8 -0)
>
> </details>
>
> I’m adding the matching Seurat container recipe now. These Dockerfiles intentionally build from the conda environment files so the Nextflow Docker profile and local conda profile share one dependency source.
>
> <details><summary>Created a file</summary>
>
> - Wrote `./containers/seurat.Dockerfile` (+8 -0)
>
> </details>
>
> I’m adding a short container README so the image names in `conf/docker.config` are buildable and not magic strings.
>
> <details><summary>Created a file, searched the web</summary>
>
> - Wrote `./containers/README.md` (+10 -0)
>
> <details><summary>Searched the web</summary>
>
> - Searched the web for `pbmc3k_filtered_gene_bc_matrices.tar.gz sha256`
>
> </details>
>
> </details>
>
> For the PBMC3k checksum I need the actual tarball digest, and it isn’t documented in the repo. I’m going to fetch the public 10x tarball into `/tmp` only, compute the SHA256, then wire that into the download script.
>
> <details><summary>Ran 2 commands</summary>
>
> - Ran `curl -L -s https://cf.10xgenomics.com/samples/cell-exp/1.1.0/pbmc3k/pbmc3k_filtered_gene_bc_matrices.tar.gz -o /tmp/pbmc3k_filtered_gene_bc_matrices.tar.gz`
> - Ran `curl -L -s https://cf.10xgenomics.com/samples/cell-exp/1.1.0/pbmc3k/pbmc3k_filtered_gene_bc_matrices.tar.gz -o /tmp/pbmc3k_filtered_gene_bc_matrices.tar.gz`
>
> </details>
>
> The checksum download succeeded into `/tmp`. I’ll compute the digest and then update the downloader to verify downloaded data before extraction.
>
> <details><summary>Edited a file, ran a command</summary>
>
> - Ran `shasum -a 256 /tmp/pbmc3k_filtered_gene_bc_matrices.tar.gz`
> - Wrote `./scripts/download_pbmc3k.sh` (+17 -0)
>
> </details>
>
> I’m adding the canonical downstream samplesheet example now; this becomes the public input interface for the production starter.
>
> <details><summary>Created a file</summary>
>
> - Wrote `./data/samplesheets/downstream_samplesheet.csv.example` (+2 -0)
>
> </details>
>
> For CI fixtures, I’m generating a tiny deterministic 10x-format matrix under `tests/fixtures/tiny_10x/`. These files need gzip compression to match real 10x input conventions, so I’m generating the data programmatically rather than hand-editing binary gzip content.
>
> <details><summary>Ran a command</summary>
>
> - Ran `python3 - <<'PY'
> from pathlib import Path
> import gzip
>
> fixture = Path('tests/fixtures/tiny_10x')
> fixture.mkdir(parents=True, exist_ok=True)
>
> genes = [
>     ('ENSG000001', 'MT-ND1'),
>     ('ENSG000002', 'MT-CO1'),
>     ('ENSG000003', 'LYZ'),
>     ('ENSG000004', 'MS4A1'),
>     ('ENSG000005', 'CD3D'),
>     ('ENSG000006', 'NKG7'),
>     ('ENSG000007', 'PPBP'),
>     ('ENSG000008', 'FCGR3A'),
>     ('ENSG000009', 'IL7R'),
>     ('ENSG000010', 'GNLY'),
>     ('ENSG000011', 'S100A8'),
>     ('ENSG000012', 'S100A9'),
>     ('ENSG000013', 'CD14'),
>     ('ENSG000014', 'CCR7'),
>     ('ENSG000015', 'LTB'),
>     ('ENSG000016', 'CST3'),
>     ('ENSG000017', 'MALAT1'),
>     ('ENSG000018', 'B2M'),
>     ('ENSG000019', 'RPL13A'),
>     ('ENSG000020', 'ACTB'),
> ]
> barcodes = [f'cell{i:02d}-1' for i in range(1, 13)]
> entries = []
> for gene_idx, (_, gene_name) in enumerate(genes, start=1):
>     for cell_idx, _ in enumerate(barcodes, start=1):
>         if gene_idx <= 2:
>             value = 1 if cell_idx % 4 == 0 else 0
>         else:
>             value = ((gene_idx * 3 + cell_idx * 2) % 5)
>         if value:
>             entries.append((gene_idx, cell_idx, value))
>
> with gzip.open(fixture / 'features.tsv.gz', 'wt') as handle:
>     for gene_id, gene_name in genes:
>         handle.write(f'{gene_id}\t{gene_name}\tGene Expression\n')
>
> with gzip.open(fixture / 'barcodes.tsv.gz', 'wt') as handle:
>     for barcode in barcodes:
>         handle.write(f'{barcode}\n')
>
> with gzip.open(fixture / 'matrix.mtx.gz', 'wt') as handle:
>     handle.write('%%MatrixMarket matrix coordinate integer general\n')
>     handle.write('% Tiny deterministic 10x fixture for CI smoke tests\n')
>     handle.write(f'{len(genes)} {len(barcodes)} {len(entries)}\n')
>     for row, col, value in entries:
>         handle.write(f'{row} {col} {value}\n')
> PY`
>
> </details>
>
> I’m adding tests around the new stable pieces: samplesheet normalization, species defaults, manifest generation, contract paths, and the checked-in fixture shape.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `./tests/test_scanpy_utils.py` (+22 -1)
>
> </details>
>
> I’m adding a focused output contract test file rather than loading Scanpy/Seurat, so the fast test layer stays lightweight.
>
> <details><summary>Created a file</summary>
>
> - Wrote `./tests/test_output_contract.py` (+41 -0)
>
> </details>
>
> I’m adding a lock-generation script now. `conda-lock` is not installed locally, so I can’t generate actual lockfiles in this environment, but the repo will have a reproducible command path for Linux and macOS ARM locks.
>
> <details><summary>Created a file, ran a command</summary>
>
> - Wrote `./scripts/generate_conda_locks.sh` (+22 -0)
> - Ran `chmod +x scripts/generate_conda_locks.sh`
>
> </details>
>
> I’m rewriting the README around the production starter flow and adding a separate output contract document so the stable interface is explicit.
>
> <details><summary>Created a file, deleted a file</summary>
>
> - Deleted `./README.md` (+0 -116)
> - Wrote `./README.md` (+128 -0)
>
> </details>
>
> The old README was portfolio-oriented, so I’m replacing it with production-starter instructions rather than trying to patch individual paragraphs.
>
> <details><summary>Created a file</summary>
>
> - Wrote `./README.md` (+132 -0)
>
> </details>
>
> I’m adding the output contract document with the required layout and summary metadata so downstream users know what is stable.
>
> <details><summary>Created a file</summary>
>
> - Wrote `./docs/output_contract.md` (+70 -0)
>
> </details>
>
> For Nextflow smoke tests I’m adding explicit `stub:` blocks. That lets CI verify workflow wiring and output layout without downloading full Seurat/Scanpy environments on every lightweight PR check.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `./main.nf` (+22 -0)
>
> </details>
>
> I’m expanding CI into fast unit checks, a Nextflow stub smoke, and optional full engine smoke jobs that create the conda environments from the repo specs and run against the tiny fixture.
>
> <details><summary>Deleted a file</summary>
>
> - Deleted `./.github/workflows/tests.yml` (+0 -27)
>
> </details>
>
> The old CI only covered utility tests, so I’m replacing it with separate jobs for fast checks, Nextflow wiring, and engine smoke tests.
>
> <details><summary>Created a file</summary>
>
> - Wrote `./.github/workflows/tests.yml` (+122 -0)
>
> </details>
>
> I’m updating the structure test so it tracks the new production interface files, not only the original portfolio scripts.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `./tests/test_repo_structure.py` (+5 -0)
>
> </details>
>
> The implementation pieces are in place. I’m going to run syntax and lightweight verification now, starting with Python compilation and utility behavior before trying the Nextflow stub path.
>
> I’m doing the verification pass now. Some full engine checks may depend on Scanpy/Seurat environments that aren’t installed locally, but the stub and utility checks should catch wiring and contract mistakes.
>
> <details><summary>Ran 3 commands</summary>
>
> - Ran `python3 - <<'PY'
> from pathlib import Path
> import json
> import pandas as pd
> from python.utils import normalize_samplesheet, write_output_manifest
>
> sheet = pd.DataFrame({'sample':['tiny'], 'matrix_dir':['tests/fixtures/tiny_10x'], 'species':['mouse']})
> assert normalize_samplesheet(sheet)['mt_prefix'].tolist() == ['mt-']
> base = Path('/tmp/single-cell-contract-check')
> (base / 'plots').mkdir(parents=True, exist_ok=True)
> (base / 'objects').mkdir(exist_ok=True)
> for name in ['cell_metadata_prefilter.csv','cell_metadata.csv','cluster_markers.csv','run_summary.json']:
>     (base / name).write_text('stub\n')
> (base / 'objects' / 'tiny.h5ad').write_text('stub\n')
> manifest = write_output_manifest(base, 'tiny', 'scanpy')
> assert all(record['exists'] for record in manifest['files'])
> assert json.loads((base / 'output_manifest.json').read_text()) == manifest
> PY`
> - Ran `python3 -m py_compile python/utils.py python/01_scanpy_pbmc_qc_cluster.py bin/make_cellranger_samplesheet.py`
> - Ran `Rscript -e "parse(file='R/01_seurat_pbmc_qc_cluster.R'); cat('R parse ok\n')"`
>
> </details>
>
> Python syntax and R parsing passed. The local Python lacks pandas/pytest, so the utility test snippet can’t run here without creating an environment. I’m still running the Nextflow stub smoke because it does not need the Scanpy or Seurat stacks.
>
> <details><summary>Ran a command</summary>
>
> - Ran `nextflow run main.nf --matrix_dir tests/fixtures/tiny_10x --sample tiny --species human --genome test --outdir /tmp/scwf_nextflow_stub --min_features 2 --max_features 100 --max_mt 100 -stub-run`
>
> </details>
>
> The Nextflow stub workflow completed and produced both engine directories. I’ll assert the expected contract files and then inspect the changed file set for any mistakes.
>
> <details><summary>Explored a search, a list, ran a command</summary>
>
> <details><summary>Explored a search, a list</summary>
>
> - Listed files in `tiny_10x`
> - Searched for `./.nextflow*` in `.`
>
> </details>
>
> - Ran `test -f /tmp/scwf_nextflow_stub/tiny/scanpy/run_summary.json && test -f /tmp/scwf_nextflow_stub/tiny/scanpy/output_manifest.json && test -f /tmp/scwf_nextflow_stub/tiny/scanpy/objects/tiny.h5ad && test -f /tmp/scwf_nextflow_stub/tiny/seurat/run_summary.json && test -f /tmp/scwf_nextflow_stub/tiny/seurat/output_manifest.json && test -f /tmp/scwf_nextflow_stub/tiny/seurat/objects/tiny.rds`
>
> </details>
>
> The stub contract assertions passed. The Python compile step created ignored `__pycache__` files, so I’m leaving them alone rather than using destructive cleanup commands in the workspace.
>
> <details><summary>Explored a list</summary>
>
> - Listed files
>
> </details>
>
> The Nextflow stub run created `work/` files and Python created `__pycache__` files inside the workspace. I’m going to clean only those generated artifacts so the repository contents remain focused on source changes.
>
> <details><summary>Ran a command</summary>
>
> - Ran `rm -rf work python/__pycache__ bin/__pycache__ .nextflow.log .nextflow`
>
> </details>
>
> Generated verification artifacts are cleaned. I’ll do one more source scan and then run the feasible checks again without leaving compiled caches where possible.
>
> <details><summary>Explored a search, 3 lists, ran 3 commands</summary>
>
> <details><summary>Explored 2 lists</summary>
>
> - Listed files
> - Listed files in `tiny_10x`
>
> </details>
>
> - Ran `which conda-lock`
>
> - Ran `Rscript -e "parse(file='R/01_seurat_pbmc_qc_cluster.R'); cat('R parse ok\n')"`
>
> - Ran `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile python/utils.py python/01_scanpy_pbmc_qc_cluster.py bin/make_cellranger_samplesheet.py`
>
> <details><summary>Explored a search, a list</summary>
>
> - Listed files
> - Searched for `__pycache__|^work/`
>
> </details>
>
> </details>
>
> `py_compile` still wrote `.pyc` files even with bytecode disabled, so I’m cleaning only those generated cache files.
>
> <details><summary>Explored a search, a list, ran a command</summary>
>
> - Ran `rm -rf python/__pycache__ bin/__pycache__`
>
> <details><summary>Explored a search, a list</summary>
>
> - Listed files
> - Searched for `__pycache__|^work/`
>
> </details>
>
> </details>
>
> The workspace is clean of generated cache/work artifacts. I’m checking whether the declared conda environments already exist locally; if they do, I can run the full tests without installing anything.
>
> <details><summary>Ran 2 commands</summary>
>
> - Ran `micromamba env list`
> - Ran `micromamba run -n base python -m pytest -q -p no:cacheprovider`
>
> </details>
>
> `micromamba run` needs to write its lockfile under the user cache outside the workspace, so the sandbox blocked it. I’ll rerun that one command with approval; it may still reveal that pytest is absent, but it’s the least invasive way to check.
>
> <details><summary>Ran a command</summary>
>
> - Ran `micromamba run -n base python -m pytest -q -p no:cacheprovider`
>
> </details>
>
> The base micromamba Python also lacks pytest, so local pytest execution is not available without installing dependencies. I’m doing static sanity checks on the new YAML/docs and then I’ll summarize what was verified and what remains environment-dependent.
>
> <details><summary>Explored a search, ran 2 commands</summary>
>
> - Ran `ruby -e "require 'yaml'; YAML.load_file('.github/workflows/tests.yml'); puts 'workflow yaml ok'"`
>
> <details><summary>Explored a search</summary>
>
> - Searched for `run_cellranger|run_summary.txt|run_summary.json|output_manifest|samplesheet|mt-prefix|cluster-resolution|conda-lock|single-cell-workflows-starter` in `README.md`
>
> </details>
>
> - Ran `ruby -e "require 'yaml'; YAML.load_file('envs/scanpy.yml'); YAML.load_file('envs/seurat.yml'); puts 'env yaml ok'"`
>
> </details>
>
> One important path I haven’t exercised yet is samplesheet parsing in `main.nf`. I’ll run a second stub smoke using a temporary samplesheet that points at the tiny fixture, then clean the generated Nextflow work files again.
>
> <details><summary>Ran 2 commands</summary>
>
> - Ran `printf 'sample,matrix_dir,species,genome,mt_prefix
> tiny,tests/fixtures/tiny_10x,mouse,test,
> ' > /tmp/scwf_samplesheet.csv`
> - Ran `nextflow run main.nf --samplesheet /tmp/scwf_samplesheet.csv --outdir /tmp/scwf_nextflow_samplesheet_stub --min_features 2 --max_features 100 --max_mt 100 -stub-run`
>
> </details>
>
> Samplesheet-based Nextflow stub execution passed. I’ll assert the outputs and clean the generated Nextflow work/log files once more.
>
> <details><summary>Explored a list, ran a command</summary>
>
> - Ran `test -f /tmp/scwf_nextflow_samplesheet_stub/tiny/scanpy/run_summary.json && test -f /tmp/scwf_nextflow_samplesheet_stub/tiny/seurat/run_summary.json`
>
> <details><summary>Explored a list</summary>
>
> - Listed files in `work`
>
> </details>
>
> </details>
>
> The samplesheet stub outputs are present. I’ll clean only the generated Nextflow artifacts from that verification run.
>
> <details><summary>Ran a command</summary>
>
> - Ran `rm -rf work .nextflow .nextflow.log`
>
> </details>
>
> Cleanup is done. I’m doing a final repository scan for generated artifacts and a focused review of changed files before the handoff summary.
>
> <details><summary>Explored 4 files, a search, 3 lists</summary>
>
> - Listed files in `generate_conda_locks.sh`
> - Listed files
> - Listed files
> - Searched for `__pycache__|^work/|^\.nextflow`
> - Read `./main.nf`
> - Read `./python/01_scanpy_pbmc_qc_cluster.py`
> - Read `./R/01_seurat_pbmc_qc_cluster.R`
> - Read `./python/utils.py`
>
> </details>
>
> I noticed one small robustness gap in the Scanpy script for pathological tiny inputs: one or two cells after filtering could reach PCA/neighbors with invalid dimensions. I’m adding a clear early error for that case.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `./python/01_scanpy_pbmc_qc_cluster.py` (+3 -1)
>
> </details>
>
> I’ll re-run Python syntax validation using `compile()` directly so it doesn’t generate bytecode files.
>
> <details><summary>Explored a search, a list, ran a command</summary>
>
> - Ran `python3 - <<'PY'
> from pathlib import Path
> for path in ['python/utils.py', 'python/01_scanpy_pbmc_qc_cluster.py', 'bin/make_cellranger_samplesheet.py']:
>     compile(Path(path).read_text(), path, 'exec')
> print('python syntax ok')
> PY`
>
> <details><summary>Explored a search, a list</summary>
>
> - Listed files
> - Searched for `__pycache__|^work/|^\.nextflow`
>
> </details>
>
> </details>
>
> No generated artifacts are present. I’m doing one tiny fixture integrity check directly with `gzip` so we know the compressed 10x fixture files are readable.
>
> <details><summary>Ran a command</summary>
>
> - Ran `python3 - <<'PY'
> import gzip
> from pathlib import Path
> fixture = Path('tests/fixtures/tiny_10x')
> for name in ['matrix.mtx.gz', 'barcodes.tsv.gz', 'features.tsv.gz']:
>     with gzip.open(fixture / name, 'rt') as handle:
>         first = handle.readline().strip()
>     assert first
> print('fixture gzip ok')
> PY`
>
> </details>
>
> Verification is complete for the parts this environment can run without installing the heavy stacks. I’ll mark the checklist complete and then give you a concise implementation summary with the exact checks and known gaps.
>
> <details><summary>Plan</summary>
>
> - [x] Inspect current repo/tooling and decide feasible lock/test path
> - [x] Update workflow config and shared Python utilities for samplesheets/contracts
> - [x] Align Scanpy and Seurat CLIs/output contracts
> - [x] Add fixtures, tests, docs, and reproducibility assets
> - [x] Run feasible verification and report residual gaps
>
> </details>
</details>

Implemented the production-starter pass.

Key changes:
- `main.nf` now supports `--samplesheet` plus single-sample compatibility, removes the fake Cell Ranger path, applies species/MT-prefix defaults, and publishes `<outdir>/<sample>/<engine>/`.
- `python/01_scanpy_pbmc_qc_cluster.py` and `R/01_seurat_pbmc_qc_cluster.R` now share production parameters and write the canonical contract: metadata, markers, `run_summary.json`, `output_manifest.json`, `plots/`, and `objects/`.
- Added shared contract/samplesheet utilities in `python/utils.py`.
- Added tiny deterministic 10x fixture under `tests/fixtures/tiny_10x/`.
- Added output-contract tests, expanded structure tests, and updated GitHub Actions with lightweight, Nextflow stub, Scanpy smoke, and Seurat smoke jobs.
- Added `docs/output_contract.md`, rewritten `README.md`, project Dockerfiles, Docker profile tags, checksum validation for PBMC3k download, and `scripts/generate_conda_locks.sh`.

Verification run:
- Python syntax check: passed.
- R script parse: passed.
- Nextflow stub smoke with `--matrix_dir`: passed.
- Nextflow stub smoke with `--samplesheet`: passed.
- Output contract assertions on stub outputs: passed.
- Fixture gzip integrity check: passed.
- Workflow/env YAML parse: passed.

Not fully run locally:
- `pytest`, Scanpy smoke, and Seurat smoke need dependencies that are not installed in this local environment.
- Actual conda lockfiles were not generated because `conda-lock` is not installed; I added the generation script targeting `linux-64` and `osx-arm64`.

> and now?

Now the right next step is **full environment validation**, because the source and stub workflow are in place but the heavy Scanpy/Seurat jobs were not run locally.

I’d do this in order:

1. Create the conda environments:
   ```bash
   micromamba create -n singlecell-python -f envs/scanpy.yml
   micromamba create -n singlecell-r -f envs/seurat.yml
   ```

2. Run the full checks:
   ```bash
   pytest
   nextflow run main.nf --matrix_dir tests/fixtures/tiny_10x --sample tiny --outdir results/tiny_full -profile conda --min_features 2 --max_features 100 --max_mt 100
   ```

3. Install `conda-lock` and generate lockfiles:
   ```bash
   micromamba install -n base -c conda-forge conda-lock
   bash scripts/generate_conda_locks.sh
   ```

4. Build the project containers:
   ```bash
   docker build -f containers/scanpy.Dockerfile -t single-cell-workflows-starter-scanpy:0.1.0 .
   docker build -f containers/seurat.Dockerfile -t single-cell-workflows-starter-seurat:0.1.0 .
   ```

After that, the repo is ready for a commit/PR. The only unresolved work is dependency-heavy validation and actual lockfile generation.

> ERROR ~ Error executing process > 'RUN_SEURAT (1)'
>
> Caused by:
>   Failed to create Conda environment
>     command: conda env create --prefix /Users/pedrodimitriu/repos/single-cell-workflows-starter/work/conda/env-b9dfbb51cc4fdf23-0af6ed5b232f4867fbc0ac8ae80bb07f --file /Users/pedrodimitriu/repos/single-cell-workflows-starter/envs/seurat.yml
>     status : 127
>     message:
>       bash: conda: command not found

<details><summary>16 previous messages</summary>

> The failure is from Nextflow trying to call `conda`, while this machine has `micromamba`. I’ll update the Nextflow conda profile so it uses micromamba and caches envs in a predictable project-local directory.
>
> <details><summary>Ran 3 commands</summary>
>
> - Ran `nextflow -help | rg -i "conda|mamba|micromamba"`
> - Ran `nextflow config -flat | rg -i "conda|mamba|micromamba"`
> - Ran `which micromamba conda mamba`
>
> </details>
>
> This confirms `conda` is absent, while `micromamba` and `mamba` are available. I’m checking Nextflow’s config/help syntax, then I’ll patch `nextflow.config` to prefer one of those.
>
> <details><summary>Ran 3 commands, searched the web</summary>
>
> - Ran `nextflow help | rg -i "conda|mamba|micromamba"`
>
> - Ran `nextflow config -h`
>
> - Ran `nextflow config -flat .`
>
> <details><summary>Searched the web</summary>
>
> - Searched the web for `Nextflow conda useMamba useMicromamba configuration`
> - Searched the web for `site:nextflow.io/docs conda.useMamba Nextflow`
>
> </details>
>
> </details>
>
> I don’t need the internet for this; Nextflow 25.04 supports Mamba through its conda config. I’ll set the conda profile to use `mamba`, which is present on this machine, and keep the change portable for CI.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `./nextflow.config` (+2 -0)
>
> </details>
>
> I’ve patched the conda profile to use `mamba`. I’m checking that Nextflow now sees those settings under `-profile conda` before suggesting a rerun.
>
> <details><summary>Ran a command</summary>
>
> - Ran `nextflow config -flat -profile conda . | rg -i "conda"`
>
> </details>
>
> The config now resolves to `conda.useMamba = true`. I’m running a stub workflow with `-profile conda` to verify the profile itself parses cleanly without creating the heavy environments.
>
> <details><summary>Ran a command</summary>
>
> - Ran `nextflow run main.nf --matrix_dir tests/fixtures/tiny_10x --sample tiny --outdir /tmp/scwf_conda_profile_stub --min_features 2 --max_features 100 --max_mt 100 -profile conda -stub-run`
>
> </details>
>
> The original `conda: command not found` is fixed: Nextflow is now invoking `mamba`. The new failure is environment creation/network/cache access, not the previous missing-command problem. I’ll clean the generated work files from this failed verification run.
>
> <details><summary>Ran a command</summary>
>
> - Ran `rm -rf work .nextflow .nextflow.log`
>
> </details>
>
> I’m adding a short README note so this doesn’t surprise the next person: `-profile conda` uses Mamba now, and it still needs network or a pre-populated package cache the first time.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `./README.md` (+2 -0)
>
> </details>
>
> I’ll confirm the config still resolves cleanly and no generated Nextflow artifacts are left in the repo.
>
> <details><summary>Explored a search, a list, ran a command</summary>
>
> <details><summary>Explored a search, a list</summary>
>
> - Listed files
> - Searched for `^work/|^\.nextflow|__pycache__`
>
> </details>
>
> - Ran `nextflow config -flat -profile conda . | rg -i "conda"`
>
> </details>
</details>

Fixed the immediate issue. `nextflow.config` now sets:

```groovy
conda.enabled = true
conda.useMamba = true
conda.cacheDir = "${projectDir}/work/conda"
```

So Nextflow will call `mamba env create ...` instead of `conda env create ...`.

What to do now:

```bash
nextflow run main.nf \
  --matrix_dir tests/fixtures/tiny_10x \
  --sample tiny \
  --outdir results/tiny_full \
  --min_features 2 \
  --max_features 100 \
  --max_mt 100 \
  -profile conda
```

The next failure, if any, will likely be package solving/download related, not `conda: command not found`. First use of `-profile conda` now requires network access because Nextflow creates its own process envs under `work/conda`.

I also added a README note explaining that the conda profile uses Mamba.

> ERROR ~ Error executing process > 'RUN_SEURAT (tiny)'
>
> Caused by:
>   Missing output file(s) `tiny/seurat` expected by process `RUN_SEURAT (tiny)`
>
> Command executed:

<details><summary>53 previous messages</summary>

> That error means the process command exited in a way Nextflow considered successful enough to check outputs, but the script did not leave the expected `tiny/seurat` directory in the work directory. I’ll inspect the Nextflow work/log files to see whether this is a workflow output-declaration issue or the Seurat script failing before it writes outputs.
>
> <details><summary>Explored a file, a search, a list</summary>
>
> - Read `./.nextflow.log`
> - Searched for `.command.*` in `work`
> - Listed files in `work`
>
> </details>
>
> The log shows the R command exited `0`, but the output directory disappeared. The command line in `.nextflow.log` also shows the matrix input is staged as `tiny_10x`, so I’m checking the actual wrapper script and work directory contents to see what happened after `mkdir -p tiny/seurat`.
>
> <details><summary>Explored 2 files, 2 lists</summary>
>
> - Listed files in `1a124117e8cc936d88bafb825c8352`
> - Read `./work/75/1a124117e8cc936d88bafb825c8352/.command.sh`
> - Read `./work/75/1a124117e8cc936d88bafb825c8352/.exitcode`
> - Listed files in `1a124117e8cc936d88bafb825c8352`
>
> </details>
>
> The work directory contains only wrapper files, which points to a staging issue: `R/01...` was not staged into the task, and because this script did not declare it as an input, behavior under conda execution is unreliable. I’ll update the processes to stage their script files explicitly and call the staged filenames.
>
> <details><summary>Explored a file</summary>
>
> - Read `./work/75/1a124117e8cc936d88bafb825c8352/.command.log`
>
> </details>
>
> The hidden command log gives the real cause: even after using Mamba to create envs, Nextflow’s wrapper still tried `conda activate`, and this machine has no `conda`. I’m checking the wrapper activation block so I can switch the profile to a Nextflow mode that works without Conda installed.
>
> <details><summary>Explored a file, searched the web</summary>
>
> <details><summary>Explored a file</summary>
>
> - Read `./work/75/1a124117e8cc936d88bafb825c8352/.command.run`
>
> </details>
>
> <details><summary>Searched the web</summary>
>
> - Searched the web for `Nextflow conda.useMicromamba configuration official docs`
> - Searched the web for `Nextflow micromamba conda.useMicromamba`
>
> </details>
>
> </details>
>
> Nextflow’s generated wrapper confirms the activation step specifically shells out to `conda info`. The fix is to use Nextflow’s micromamba activation mode, not just Mamba solving. I’m going to update the conda profile accordingly and then verify the wrapper no longer contains `conda info`.
>
> <details><summary>Explored a search, ran 2 commands</summary>
>
> - Ran `which nextflow && head -n 80 $(which nextflow)`
>
> <details><summary>Explored a search</summary>
>
> - Searched for `useMicromamba|useMamba|micromamba|conda info` in `libexec`
>
> </details>
>
> - Ran `file /opt/homebrew/Cellar/nextflow/25.04.8/libexec/nextflow && ls -la /opt/homebrew/Cellar/nextflow/25.04.8/libexec`
>
> </details>
>
> I’m checking the installed Nextflow launcher for the exact micromamba setting name instead of guessing from memory.
>
> <details><summary>Explored a list, ran a command</summary>
>
> - Ran `strings /opt/homebrew/Cellar/nextflow/25.04.8/libexec/nextflow | rg "useMamba|useMicromamba|micromamba|conda info"`
>
> <details><summary>Explored a list</summary>
>
> - Listed files in `.nextflow`
>
> </details>
>
> </details>
>
> I found the cached Nextflow framework jar and will inspect it for the config property names.
>
> <details><summary>Ran a command</summary>
>
> - Ran `jar tf /Users/pedrodimitriu/.nextflow/framework/26.04.0/nextflow-26.04.0-one.jar | rg 'Conda|conda' | head -n 80`
>
> </details>
>
> The system `jar` isn’t on PATH, but Nextflow’s bundled Java path is available through Homebrew. I’ll use that to inspect the jar.
>
> <details><summary>Ran a command</summary>
>
> - Ran `/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home/bin/jar tf /Users/pedrodimitriu/.nextflow/framework/26.04.0/nextflow-26.04.0-one.jar | rg 'Conda|conda' | head -n 120`
>
> </details>
>
> I can now decompile enough of the config class with `javap` to verify the activation behavior.
>
> <details><summary>Ran a command</summary>
>
> - Ran `/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home/bin/javap -classpath /Users/pedrodimitriu/.nextflow/framework/26.04.0/nextflow-26.04.0-one.jar -private nextflow.conda.CondaConfig | sed -n '1,220p'`
>
> </details>
>
> The config class has a distinct `useMicromamba` switch. I’m changing the conda profile from Mamba mode to Micromamba mode, because this host has `micromamba` and no `conda`.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `./nextflow.config` (+1 -1)
>
> </details>
>
> I’ll update the README note to say micromamba specifically, then run a controlled stub check and inspect the generated wrapper activation block.
>
> <details><summary>Edited a file, ran 2 commands</summary>
>
> - Wrote `./README.md` (+1 -1)
> - Ran `micromamba --version`
> - Ran `nextflow config -flat -profile conda . | rg -i "conda|mamba"`
>
> </details>
>
> There is a second issue queued up after activation: the process command calls `R/01...` and `python/01...` relative to the task work directory, where those repo paths are not staged. I’m switching those calls to absolute `${projectDir}` paths so the scripts are always found.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `./main.nf` (+2 -2)
>
> </details>
>
> I’ll run a stub check now. It may still need to create the Scanpy env if it wasn’t cached yet, so if it fails on network/package solving I’ll still inspect whether the wrapper generation has moved to micromamba.
>
> <details><summary>Ran a command</summary>
>
> - Ran `nextflow run main.nf --matrix_dir tests/fixtures/tiny_10x --sample tiny --outdir /tmp/scwf_micromamba_stub --min_features 2 --max_features 100 --max_mt 100 -profile conda -stub-run`
>
> </details>
>
> The missing-output error is fixed: `RUN_SEURAT` completed successfully under `-profile conda` after switching to micromamba and absolute script paths. The remaining failure is Scanpy env creation due the sandbox blocking Conda network/cache access, so I’m rerunning the same validation with escalation as required.
>
> <details><summary>Ran a command</summary>
>
> - Ran `nextflow run main.nf --matrix_dir tests/fixtures/tiny_10x --sample tiny --outdir /tmp/scwf_micromamba_stub --min_features 2 --max_features 100 --max_mt 100 -profile conda -stub-run`
>
> </details>
>
> The escalated validation is still running while micromamba builds the Scanpy env. Seurat has already passed in this run, which confirms the specific missing-output error is resolved.
>
> The conda-profile stub run now passes for both engines. I’m going to run the full tiny-fixture workflow next, using the cached envs, because that will catch script-level issues beyond Nextflow wiring.
>
> <details><summary>Ran a command</summary>
>
> - Ran `nextflow run main.nf --matrix_dir tests/fixtures/tiny_10x --sample tiny --outdir /tmp/scwf_full_tiny --min_features 2 --max_features 100 --max_mt 100 -profile conda`
>
> </details>
>
> The full workflow is running both real Seurat and Scanpy tasks against the tiny fixture now. I’ll wait for completion and fix any script-level failures that appear.
>
> The original Nextflow/conda issue is resolved. The full tiny run exposed a real small-fixture Seurat bug: UMAP’s default neighbor count is too large for 12 cells. I’m making the Seurat script choose neighbor counts from the filtered cell count.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `./R/01_seurat_pbmc_qc_cluster.R` (+3 -2)
>
> </details>
>
> I’ll resume the full run. Since the envs are cached, this should execute the actual scripts and reveal whether Scanpy has a similar tiny-fixture edge case.
>
> <details><summary>Ran a command</summary>
>
> - Ran `nextflow run main.nf --matrix_dir tests/fixtures/tiny_10x --sample tiny --outdir /tmp/scwf_full_tiny --min_features 2 --max_features 100 --max_mt 100 -profile conda -resume`
>
> </details>
>
> Seurat now completes in the full run. Scanpy is still running; I’ll wait for its result.
>
> Scanpy hit the same kind of tiny-fixture edge case: HVG selection left too few features for PCA. I’m changing the fallback so small/synthetic inputs keep all genes unless at least two highly variable genes are selected, and I’ll set local Matplotlib/font caches inside the task to avoid cache warnings.
>
> <details><summary>Edited 2 files</summary>
>
> - Wrote `./python/01_scanpy_pbmc_qc_cluster.py` (+2 -1)
> - Wrote `./main.nf` (+2 -0)
>
> </details>
>
> I’ll resume the full workflow again. Seurat should remain cached/successful; this rerun should focus on the Scanpy script change.
>
> <details><summary>Ran a command</summary>
>
> - Ran `nextflow run main.nf --matrix_dir tests/fixtures/tiny_10x --sample tiny --outdir /tmp/scwf_full_tiny --min_features 2 --max_features 100 --max_mt 100 -profile conda -resume`
>
> </details>
>
> The fallback still allowed a zero-feature subset, so Scanpy’s HVG column is likely not a plain boolean mask in this environment. I’m checking the actual HVG values on the tiny fixture inside the cached Scanpy env and then I’ll make the condition stricter.
>
> <details><summary>Explored a file, ran a command</summary>
>
> - Ran `work/conda/env-baa18c678617b038-f662e741469b1b1cbdd3f81198a0464f/bin/python - <<'PY'
> import scanpy as sc
> adata = sc.read_10x_mtx('tests/fixtures/tiny_10x', var_names='gene_symbols', cache=False)
> adata.var_names_make_unique()
> adata.var['mt'] = adata.var_names.str.upper().str.startswith('MT-')
> sc.pp.calculate_qc_metrics(adata, qc_vars=['mt'], percent_top=None, log1p=False, inplace=True)
> adata = adata[adata.obs['n_genes_by_counts'] > 2, :].copy()
> adata = adata[adata.obs['n_genes_by_counts'] < 100, :].copy()
> adata = adata[adata.obs['pct_counts_mt'] < 100, :].copy()
> sc.pp.normalize_total(adata, target_sum=1e4)
> sc.pp.log1p(adata)
> sc.pp.highly_variable_genes(adata, min_mean=0.0125, max_mean=3, min_disp=0.5)
> print(adata.shape)
> print(adata.var['highly_variable'].dtype)
> print(adata.var['highly_variable'].tolist())
> print(int(adata.var['highly_variable'].sum()))
> PY`
>
> <details><summary>Explored a file</summary>
>
> - Read `./python/01_scanpy_pbmc_qc_cluster.py`
>
> </details>
>
> </details>
>
> The utility check shows HVG count is zero and the current code should keep all genes. I’m running the Scanpy script directly inside the cached env to reproduce outside Nextflow; that will tell me whether this is a script issue or a stale Nextflow work directory/resume artifact.
>
> <details><summary>Ran a command</summary>
>
> - Ran `MPLCONFIGDIR=/tmp/scwf-mpl XDG_CACHE_HOME=/tmp/scwf-cache work/conda/env-baa18c678617b038-f662e741469b1b1cbdd3f81198a0464f/bin/python python/01_scanpy_pbmc_qc_cluster.py --input tests/fixtures/tiny_10x --outdir /tmp/scwf_direct_scanpy --sample tiny --species human --genome test --mt-prefix MT- --min-features 2 --max-features 100 --max-mt 100 --cluster-resolution 0.5`
>
> </details>
>
> Scanpy’s PCA automatically uses `adata.var['highly_variable']` when that column exists, even if we did not subset. With zero HVGs, PCA sees zero features. I’m forcing PCA to use the current matrix explicitly when HVG selection is skipped.
>
> <details><summary>Edited a file</summary>
>
> - Wrote `./python/01_scanpy_pbmc_qc_cluster.py` (+3 -1)
>
> </details>
>
> I’ll rerun the direct Scanpy script first; it’s faster than a full Nextflow cycle and confirms the script fix.
>
> <details><summary>Ran a command</summary>
>
> - Ran `MPLCONFIGDIR=/tmp/scwf-mpl XDG_CACHE_HOME=/tmp/scwf-cache work/conda/env-baa18c678617b038-f662e741469b1b1cbdd3f81198a0464f/bin/python python/01_scanpy_pbmc_qc_cluster.py --input tests/fixtures/tiny_10x --outdir /tmp/scwf_direct_scanpy --sample tiny --species human --genome test --mt-prefix MT- --min-features 2 --max-features 100 --max-mt 100 --cluster-resolution 0.5`
>
> </details>
>
> The direct Scanpy run now succeeds and writes the contract outputs. I’ll resume the full Nextflow run once more to verify both engines together.
>
> <details><summary>Ran a command</summary>
>
> - Ran `nextflow run main.nf --matrix_dir tests/fixtures/tiny_10x --sample tiny --outdir /tmp/scwf_full_tiny --min_features 2 --max_features 100 --max_mt 100 -profile conda -resume`
>
> </details>
>
> The full conda-profile Nextflow run passes now. I’m going to assert the output contract files and run the lightweight pytest suite using the cached Scanpy env, since it includes pytest.
>
> <details><summary>Ran 3 commands</summary>
>
> - Ran `test -f /tmp/scwf_full_tiny/tiny/seurat/run_summary.json && test -f /tmp/scwf_full_tiny/tiny/seurat/output_manifest.json && test -f /tmp/scwf_full_tiny/tiny/seurat/objects/tiny.rds && test -f /tmp/scwf_full_tiny/tiny/scanpy/run_summary.json && test -f /tmp/scwf_full_tiny/tiny/scanpy/output_manifest.json && test -f /tmp/scwf_full_tiny/tiny/scanpy/objects/tiny.h5ad`
> - Ran `work/conda/env-baa18c678617b038-f662e741469b1b1cbdd3f81198a0464f/bin/python -m pytest -q -p no:cacheprovider`
> - Ran `nextflow config -flat -profile conda . | rg -i "conda|mamba"`
>
> </details>
</details>

Fixed.

Root causes were two separate issues:
- Nextflow was still trying to activate envs through `conda`, even after creating them with Mamba. I changed the profile to `conda.useMicromamba = true`.
- The workflow called `R/...` and `python/...` relative to the task work directory. I changed those to `${projectDir}/...`.

While validating the full run, I also fixed two tiny-fixture edge cases:
- Seurat UMAP now uses a neighbor count smaller than the filtered cell count.
- Scanpy now skips HVG masking when HVG selection returns too few genes.

Verified:
```bash
nextflow run main.nf \
  --matrix_dir tests/fixtures/tiny_10x \
  --sample tiny \
  --outdir /tmp/scwf_full_tiny \
  --min_features 2 \
  --max_features 100 \
  --max_mt 100 \
  -profile conda \
  -resume
```

Result: both `RUN_SEURAT` and `RUN_SCANPY` completed successfully.

Also ran:
```bash
pytest -q -p no:cacheprovider
```

Result: `9 passed`.

You can rerun your original command with `-resume`.

> nextflow run main.nf \
>   --matrix_dir tests/fixtures/tiny_10x \
>   --sample tiny \
>   --outdir /tmp/scwf_full_tiny \
>   --min_features 2 \
>   --max_features 100 \
>   --max_mt 100 \
>   -profile conda \
>   -resume
> Nextflow 26.04.3 is available - Please consider updating your version to it
>
>  N E X T F L O W   ~  version 25.04.8
>
> Launching `main.nf` [peaceful_lichterman] DSL2 - revision: 7535e1cef9
>
> [2e/42eb8c] RUN_SEURAT (tiny) | 1 of 1, cached: 1 ✔
> [2c/87b356] RUN_SCANPY (tiny) | 1 of 1, cached: 1 ✔

Good. That means the productionized workflow is now running end-to-end with the conda/micromamba profile and both engine outputs are cached successfully.

You can inspect the contract outputs here:

```bash
ls -R /tmp/scwf_full_tiny/tiny
```

Expected key files:

```text
/tmp/scwf_full_tiny/tiny/seurat/run_summary.json
/tmp/scwf_full_tiny/tiny/seurat/output_manifest.json
/tmp/scwf_full_tiny/tiny/seurat/objects/tiny.rds
/tmp/scwf_full_tiny/tiny/scanpy/run_summary.json
/tmp/scwf_full_tiny/tiny/scanpy/output_manifest.json
/tmp/scwf_full_tiny/tiny/scanpy/objects/tiny.h5ad
```

At this point I’d commit the changes, then run the same workflow on PBMC3k as the real smoke test.

> what should i commit?

<details><summary>6 previous messages</summary>

> I’ll check the current file state and group the changes into sensible commit boundaries.
>
> <details><summary>Ran 3 commands</summary>
>
> - Ran `git status --short`
> - Ran `git diff --name-status`
> - Ran `git diff --stat`
>
> </details>
>
> This directory is not currently a Git repository from the shell’s point of view, so I can’t give you `git status`-based staging commands. I’ll list the source files present and group what should be committed.
>
> <details><summary>Explored a list</summary>
>
> - Listed files
>
> </details>
>
> I see generated `work/` and `__pycache__/` files in the tree from validation. Those should not be committed; I’m checking `.gitignore` so the recommendation matches what Git will actually ignore once you run this from a real repo checkout.
>
> <details><summary>Explored a file</summary>
>
> - Read `./.gitignore`
>
> </details>
</details>

Commit the production-starter source changes, not generated outputs.

Suggested single commit:

```bash
git add \
  main.nf \
  nextflow.config \
  conf/docker.config \
  README.md \
  docs/output_contract.md \
  python/utils.py \
  python/01_scanpy_pbmc_qc_cluster.py \
  R/01_seurat_pbmc_qc_cluster.R \
  envs/seurat.yml \
  envs/install_r_packages.R \
  scripts/download_pbmc3k.sh \
  scripts/generate_conda_locks.sh \
  containers/README.md \
  containers/scanpy.Dockerfile \
  containers/seurat.Dockerfile \
  data/samplesheets/downstream_samplesheet.csv.example \
  tests/test_repo_structure.py \
  tests/test_scanpy_utils.py \
  tests/test_output_contract.py \
  tests/fixtures/tiny_10x/matrix.mtx.gz \
  tests/fixtures/tiny_10x/barcodes.tsv.gz \
  tests/fixtures/tiny_10x/features.tsv.gz \
  .github/workflows/tests.yml
```

Commit message:

```bash
git commit -m "Productionize downstream scRNA-seq starter"
```

Do **not** commit:
- `work/`
- `.nextflow*`
- `results/`
- `reports/`
- `__pycache__/`
- `*.pyc`
- generated `.h5ad`, `.rds`, plots, or metadata outputs

Those are already covered by `.gitignore`.

One caveat: from my shell this directory is **not currently a Git repo** (`git status` says not a repository). If you expect it to be one, check whether you’re in the right checkout or whether `.git` is missing.

