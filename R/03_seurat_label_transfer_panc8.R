#!/usr/bin/env Rscript

# Seurat label-transfer example using the panc8 dataset.
# This demonstrates reference construction, anchor finding, and transfer of known labels to a query dataset.

suppressPackageStartupMessages({
  library(optparse)
  library(Seurat)
  library(SeuratData)
  library(ggplot2)
})

option_list <- list(
  make_option("--outdir", type = "character", default = "results/seurat_panc8_label_transfer", help = "Output directory")
)

opt <- parse_args(OptionParser(option_list = option_list))
dir.create(opt$outdir, recursive = TRUE, showWarnings = FALSE)

# Install panc8 on first use if needed.
if (!"panc8" %in% InstalledData()[, "Dataset"]) {
  InstallData("panc8")
}

# Load pancreas datasets from multiple technologies.
data("panc8")
panc8 <- UpdateSeuratObject(panc8)

# Use some technologies as a reference and one as a query.
reference <- subset(panc8, subset = tech != "fluidigmc1")
query <- subset(panc8, subset = tech == "fluidigmc1")

# Normalize and find variable features for both reference and query.
reference <- NormalizeData(reference)
reference <- FindVariableFeatures(reference)
reference <- ScaleData(reference)
reference <- RunPCA(reference)
reference <- RunUMAP(reference, dims = 1:30)

query <- NormalizeData(query)
query <- FindVariableFeatures(query)
query <- ScaleData(query)
query <- RunPCA(query)

# Find transfer anchors between reference and query.
anchors <- FindTransferAnchors(
  reference = reference,
  query = query,
  dims = 1:30,
  reference.reduction = "pca"
)

# Transfer cell-type labels from reference to query.
predictions <- TransferData(
  anchorset = anchors,
  refdata = reference$celltype,
  dims = 1:30
)

query <- AddMetaData(query, metadata = predictions)

# Project query cells onto the reference UMAP.
query <- MapQuery(
  anchorset = anchors,
  query = query,
  reference = reference,
  refdata = list(celltype = "celltype"),
  reference.reduction = "pca",
  reduction.model = "umap"
)

# Save predicted labels and confidence scores.
write.csv(query@meta.data, file.path(opt$outdir, "query_label_predictions.csv"))

# Plot projected query labels.
p <- DimPlot(query, reduction = "ref.umap", group.by = "predicted.celltype", label = TRUE, repel = TRUE)
ggsave(file.path(opt$outdir, "query_projected_predicted_labels.png"), p, width = 8, height = 5, dpi = 150)

# Save query object with predictions.
saveRDS(query, file.path(opt$outdir, "panc8_query_label_transfer.rds"))
