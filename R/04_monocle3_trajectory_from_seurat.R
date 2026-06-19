#!/usr/bin/env Rscript

# Optional Monocle3 trajectory example from a Seurat object.
# This script assumes the Seurat object already has UMAP coordinates and clusters.
# Install monocle3 separately following the official documentation.

suppressPackageStartupMessages({
  library(optparse)
  library(Seurat)
  library(monocle3)
  library(ggplot2)
})

option_list <- list(
  make_option("--seurat_rds", type = "character", help = "Input Seurat RDS file"),
  make_option("--outdir", type = "character", default = "results/monocle3_trajectory", help = "Output directory")
)

opt <- parse_args(OptionParser(option_list = option_list))

if (is.null(opt$seurat_rds)) {
  stop("Missing --seurat_rds")
}

dir.create(opt$outdir, recursive = TRUE, showWarnings = FALSE)

# Load Seurat object.
obj <- readRDS(opt$seurat_rds)

# Extract expression counts and metadata.
counts <- GetAssayData(obj, assay = "RNA", slot = "counts")
cell_metadata <- obj@meta.data
gene_metadata <- data.frame(gene_short_name = rownames(counts), row.names = rownames(counts))

# Create a Monocle3 cell_data_set object.
cds <- new_cell_data_set(
  expression_data = counts,
  cell_metadata = cell_metadata,
  gene_metadata = gene_metadata
)

# Preprocess and reduce dimensionality.
cds <- preprocess_cds(cds, num_dim = 50)
cds <- reduce_dimension(cds, reduction_method = "UMAP")

# Cluster cells and learn a principal graph.
cds <- cluster_cells(cds)
cds <- learn_graph(cds)

# In a non-interactive script, root selection should be defined from metadata.
message("Choose root cells/nodes deliberately before calling order_cells() in a real analysis.")

# Save trajectory plot without pseudotime ordering.
png(file.path(opt$outdir, "monocle3_trajectory_graph.png"), width = 900, height = 700)
print(plot_cells(cds, color_cells_by = "cluster", label_groups_by_cluster = TRUE, label_leaves = TRUE, label_branch_points = TRUE))
dev.off()

saveRDS(cds, file.path(opt$outdir, "monocle3_cds.rds"))
