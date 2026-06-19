#!/usr/bin/env Rscript

# Run a production-oriented Seurat workflow for a 10x filtered matrix.

suppressPackageStartupMessages({
  library(optparse)
  library(Seurat)
  library(ggplot2)
  library(patchwork)
  library(jsonlite)
})

contract_version <- "1.0.0"

normalize_args <- function(args) {
  replacements <- c(
    "--project" = "--sample",
    "--min_features" = "--min-features",
    "--max_features" = "--max-features",
    "--max_mt" = "--max-mt",
    "--cluster_resolution" = "--cluster-resolution",
    "--mt_prefix" = "--mt-prefix"
  )
  for (old in names(replacements)) {
    args[args == old] <- replacements[[old]]
  }
  args
}

default_mt_prefix <- function(species, mt_prefix = NULL) {
  if (!is.null(mt_prefix) && nzchar(trimws(mt_prefix))) {
    return(trimws(mt_prefix))
  }

  species <- tolower(trimws(ifelse(is.null(species) || !nzchar(species), "human", species)))
  if (species %in% c("mouse", "mus musculus", "mm10", "grcm38", "grcm39")) {
    return("mt-")
  }
  "MT-"
}

package_version <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    return("not-installed")
  }
  as.character(utils::packageVersion(pkg))
}

write_manifest <- function(outdir, sample, engine) {
  object_ext <- ifelse(engine == "seurat", "rds", "h5ad")
  required_paths <- c(
    "cell_metadata_prefilter.csv",
    "cell_metadata.csv",
    "cluster_markers.csv",
    "run_summary.json",
    "output_manifest.json",
    "plots",
    file.path("objects", paste0(sample, ".", object_ext))
  )

  files <- lapply(required_paths, function(path) {
    list(
      path = path,
      required = TRUE,
      exists = identical(path, "output_manifest.json") || file.exists(file.path(outdir, path))
    )
  })

  manifest <- list(
    contract_version = contract_version,
    sample = sample,
    engine = engine,
    files = files
  )
  jsonlite::write_json(
    manifest,
    file.path(outdir, "output_manifest.json"),
    pretty = TRUE,
    auto_unbox = TRUE
  )
}

option_list <- list(
  make_option("--input", type = "character", help = "10x matrix directory"),
  make_option("--outdir", type = "character", default = "results/seurat_pbmc", help = "Output directory"),
  make_option("--sample", type = "character", default = "pbmc", help = "Sample/project name"),
  make_option("--species", type = "character", default = "human", help = "Species label used for metadata defaults"),
  make_option("--genome", type = "character", default = "", help = "Genome/reference label recorded in run metadata"),
  make_option("--mt-prefix", dest = "mt_prefix", type = "character", default = NULL, help = "Mitochondrial gene prefix"),
  make_option("--min-features", dest = "min_features", type = "integer", default = 200, help = "Minimum detected genes per cell"),
  make_option("--max-features", dest = "max_features", type = "integer", default = 2500, help = "Maximum detected genes per cell"),
  make_option("--max-mt", dest = "max_mt", type = "double", default = 5, help = "Maximum mitochondrial percentage"),
  make_option("--cluster-resolution", dest = "cluster_resolution", type = "double", default = 0.5, help = "Clustering resolution")
)

opt <- parse_args(OptionParser(option_list = option_list), args = normalize_args(commandArgs(trailingOnly = TRUE)))

if (is.null(opt$input)) {
  stop("Missing --input")
}

plots_dir <- file.path(opt$outdir, "plots")
objects_dir <- file.path(opt$outdir, "objects")
dir.create(opt$outdir, recursive = TRUE, showWarnings = FALSE)
dir.create(plots_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(objects_dir, recursive = TRUE, showWarnings = FALSE)

mt_prefix <- default_mt_prefix(opt$species, opt$mt_prefix)

counts <- Read10X(data.dir = opt$input)
obj <- CreateSeuratObject(
  counts = counts,
  project = opt$sample,
  min.cells = 3,
  min.features = opt$min_features
)

cells_before_qc <- ncol(obj)
genes_before_qc <- nrow(obj)

mt_features <- rownames(obj)[startsWith(toupper(rownames(obj)), toupper(mt_prefix))]
if (length(mt_features) > 0) {
  obj[["percent.mt"]] <- PercentageFeatureSet(obj, features = mt_features)
} else {
  obj[["percent.mt"]] <- 0
}

write.csv(obj@meta.data, file.path(opt$outdir, "cell_metadata_prefilter.csv"))

qc_plot <- VlnPlot(
  obj,
  features = c("nFeature_RNA", "nCount_RNA", "percent.mt"),
  ncol = 3,
  pt.size = 0.1
)
qc_plot_path <- file.path(plots_dir, "qc_violin_prefilter.png")
ggsave(qc_plot_path, qc_plot, width = 10, height = 4, dpi = 150)
file.copy(qc_plot_path, file.path(opt$outdir, "qc_violin_prefilter.png"), overwrite = TRUE)

obj <- subset(
  obj,
  subset = nFeature_RNA > opt$min_features &
    nFeature_RNA < opt$max_features &
    percent.mt < opt$max_mt
)
if (ncol(obj) == 0) {
  stop("No cells remained after QC filtering. Relax thresholds or inspect input data.")
}

obj <- NormalizeData(obj)
obj <- FindVariableFeatures(obj, selection.method = "vst", nfeatures = min(2000, nrow(obj)))
obj <- ScaleData(obj, features = rownames(obj))

n_pcs <- min(10, ncol(obj) - 1, length(VariableFeatures(obj)))
if (n_pcs < 1) {
  stop("At least two cells and one variable feature are required for PCA.")
}
obj <- RunPCA(obj, features = VariableFeatures(obj), npcs = n_pcs)

dims <- seq_len(n_pcs)
neighbor_count <- min(20, ncol(obj) - 1)
obj <- FindNeighbors(obj, dims = dims, k.param = neighbor_count)
obj <- FindClusters(obj, resolution = opt$cluster_resolution)
obj <- RunUMAP(obj, dims = dims, n.neighbors = neighbor_count)

umap_plot <- DimPlot(obj, reduction = "umap", label = TRUE) + NoLegend()
umap_plot_path <- file.path(plots_dir, "umap_clusters.png")
ggsave(umap_plot_path, umap_plot, width = 7, height = 5, dpi = 150)
file.copy(umap_plot_path, file.path(opt$outdir, "umap_clusters.png"), overwrite = TRUE)

cluster_count <- length(unique(Idents(obj)))
if (cluster_count > 1) {
  markers <- FindAllMarkers(
    obj,
    only.pos = TRUE,
    min.pct = 0.25,
    logfc.threshold = 0.25
  )
} else {
  markers <- data.frame(
    p_val = numeric(),
    avg_log2FC = numeric(),
    pct.1 = numeric(),
    pct.2 = numeric(),
    p_val_adj = numeric(),
    cluster = character(),
    gene = character()
  )
}

write.csv(markers, file.path(opt$outdir, "cluster_markers.csv"), row.names = FALSE)
write.csv(obj@meta.data, file.path(opt$outdir, "cell_metadata.csv"))

canonical_rds <- file.path(objects_dir, paste0(opt$sample, ".rds"))
legacy_rds <- file.path(opt$outdir, paste0(opt$sample, "_seurat.rds"))
saveRDS(obj, canonical_rds)
file.copy(canonical_rds, legacy_rds, overwrite = TRUE)

summary <- list(
  contract_version = contract_version,
  engine = "seurat",
  sample = opt$sample,
  input_path = normalizePath(opt$input, mustWork = FALSE),
  species = opt$species,
  genome = opt$genome,
  mt_prefix = mt_prefix,
  thresholds = list(
    min_features = opt$min_features,
    max_features = opt$max_features,
    max_mt = opt$max_mt,
    cluster_resolution = opt$cluster_resolution
  ),
  cells_before_qc = cells_before_qc,
  genes_before_qc = genes_before_qc,
  cells_after_qc = ncol(obj),
  genes_used_for_clustering = nrow(obj),
  clusters = cluster_count,
  versions = list(
    r = R.Version()$version.string,
    seurat = package_version("Seurat"),
    seurat_object = package_version("SeuratObject"),
    ggplot2 = package_version("ggplot2")
  )
)
jsonlite::write_json(summary, file.path(opt$outdir, "run_summary.json"), pretty = TRUE, auto_unbox = TRUE)

summary_df <- data.frame(
  project = opt$sample,
  cells_after_qc = ncol(obj),
  genes = nrow(obj),
  clusters = cluster_count
)
write.csv(summary_df, file.path(opt$outdir, "run_summary.csv"), row.names = FALSE)
write_manifest(opt$outdir, opt$sample, "seurat")
