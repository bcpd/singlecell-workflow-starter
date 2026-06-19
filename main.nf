#!/usr/bin/env nextflow

/*
 * Production starter for downstream scRNA-seq analysis.
 *
 * This workflow starts from existing 10x filtered matrices. Raw FASTQ-to-count
 * generation is intentionally delegated to nf-core/scrnaseq or Cell Ranger.
 */

nextflow.enable.dsl = 2

def cleanValue(value, fallback = "") {
    def cleaned = value == null ? "" : value.toString().trim()
    return cleaned ? cleaned : fallback
}

def defaultMtPrefix(species, mtPrefix) {
    def explicitPrefix = cleanValue(mtPrefix)
    if (explicitPrefix) {
        return explicitPrefix
    }

    def normalizedSpecies = cleanValue(species, "human").toLowerCase()
    if (["mouse", "mus musculus", "mm10", "grcm38", "grcm39"].contains(normalizedSpecies)) {
        return "mt-"
    }
    return "MT-"
}

if (!params.samplesheet && !params.matrix_dir) {
    error "Provide --samplesheet with sample,matrix_dir columns or provide --matrix_dir with --sample for one sample."
}

if (params.samplesheet && params.matrix_dir) {
    log.warn "Both --samplesheet and --matrix_dir were provided. Using --samplesheet and ignoring single-sample flags."
}

if (params.samplesheet) {
    Channel
        .fromPath(params.samplesheet)
        .ifEmpty { error "Samplesheet not found: ${params.samplesheet}" }
        .splitCsv(header: true)
        .map { row ->
            def sample = cleanValue(row.sample)
            def matrixDir = cleanValue(row.matrix_dir)
            if (!sample || !matrixDir) {
                error "Samplesheet rows must include non-empty sample and matrix_dir values."
            }

            def species = cleanValue(row.species, params.species)
            def genome = cleanValue(row.genome, params.genome)
            def mtPrefix = defaultMtPrefix(species, row.mt_prefix)
            tuple(sample, file(matrixDir), species, genome, mtPrefix)
        }
        .set { ch_matrix }
} else {
    def sample = cleanValue(params.sample)
    if (!sample) {
        error "Provide a non-empty --sample when using --matrix_dir."
    }
    def species = cleanValue(params.species, "human")
    def genome = cleanValue(params.genome)
    def mtPrefix = defaultMtPrefix(species, params.mt_prefix)
    Channel
        .of(tuple(sample, file(params.matrix_dir), species, genome, mtPrefix))
        .set { ch_matrix }
}

process RUN_SEURAT {
    tag "${sample}"

    publishDir "${params.outdir}", mode: "copy"

    conda "envs/seurat.yml"

    input:
    tuple val(sample), path(matrix_dir), val(species), val(genome), val(mt_prefix)

    output:
    path "${sample}/seurat", emit: seurat_outputs

    script:
    """
    mkdir -p ${sample}/seurat

    Rscript ${projectDir}/R/01_seurat_pbmc_qc_cluster.R \
      --input ${matrix_dir} \
      --outdir ${sample}/seurat \
      --sample '${sample}' \
      --species '${species}' \
      --genome '${genome}' \
      --mt-prefix '${mt_prefix}' \
      --min-features ${params.min_features} \
      --max-features ${params.max_features} \
      --max-mt ${params.max_mt} \
      --cluster-resolution ${params.cluster_resolution}
    """

    stub:
    """
    mkdir -p ${sample}/seurat/plots ${sample}/seurat/objects
    touch ${sample}/seurat/cell_metadata_prefilter.csv
    touch ${sample}/seurat/cell_metadata.csv
    touch ${sample}/seurat/cluster_markers.csv
    touch ${sample}/seurat/objects/${sample}.rds
    printf '{"contract_version":"1.0.0","engine":"seurat","sample":"%s"}\\n' '${sample}' > ${sample}/seurat/run_summary.json
    printf '{"contract_version":"1.0.0","engine":"seurat","sample":"%s","files":[]}\\n' '${sample}' > ${sample}/seurat/output_manifest.json
    """
}

process RUN_SCANPY {
    tag "${sample}"

    publishDir "${params.outdir}", mode: "copy"

    conda "envs/scanpy.yml"

    input:
    tuple val(sample), path(matrix_dir), val(species), val(genome), val(mt_prefix)

    output:
    path "${sample}/scanpy", emit: scanpy_outputs

    script:
    """
    mkdir -p ${sample}/scanpy
    export MPLCONFIGDIR="\$PWD/.matplotlib"
    export XDG_CACHE_HOME="\$PWD/.cache"

    python ${projectDir}/python/01_scanpy_pbmc_qc_cluster.py \
      --input ${matrix_dir} \
      --outdir ${sample}/scanpy \
      --sample '${sample}' \
      --species '${species}' \
      --genome '${genome}' \
      --mt-prefix '${mt_prefix}' \
      --min-features ${params.min_features} \
      --max-features ${params.max_features} \
      --max-mt ${params.max_mt} \
      --cluster-resolution ${params.cluster_resolution}
    """

    stub:
    """
    mkdir -p ${sample}/scanpy/plots ${sample}/scanpy/objects
    touch ${sample}/scanpy/cell_metadata_prefilter.csv
    touch ${sample}/scanpy/cell_metadata.csv
    touch ${sample}/scanpy/cluster_markers.csv
    touch ${sample}/scanpy/objects/${sample}.h5ad
    printf '{"contract_version":"1.0.0","engine":"scanpy","sample":"%s"}\\n' '${sample}' > ${sample}/scanpy/run_summary.json
    printf '{"contract_version":"1.0.0","engine":"scanpy","sample":"%s","files":[]}\\n' '${sample}' > ${sample}/scanpy/output_manifest.json
    """
}

workflow {
    // Run both downstream analyses from the same count matrix.
    RUN_SEURAT(ch_matrix)
    RUN_SCANPY(ch_matrix)
}
