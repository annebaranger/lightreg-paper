# =============================================================================
# Demo pipeline: full TLS + light processing chain for one plot (GER34), from
# the files in data/demo_GER34/. It
#   1. recomputes the TLS / light metrics of GER34,
#   2. checks them against the GER34 rows of the tables in data/analysis/,
#   3. builds the 3D light example figure (mainfig_light3d_GER34).
#
# Run with:  Sys.setenv(TAR_PROJECT = "demo"); targets::tar_make()
# The H_ext step fits one GAM per voxel column and can take a while.
# =============================================================================

library(targets)
tar_source(files = "R")
tar_option_set(packages = c("dplyr", "ggplot2", "data.table", "tidyr", "readr",
                            "terra", "sf", "purrr", "tibble", "mgcv", "lidR"))

plot_name <- "GER34"
demo_dir  <- "data/demo_GER34"
out_dir   <- "output/demo"     # intermediate files written by the pipeline

if (!dir.exists(demo_dir))
  stop("Folder '", demo_dir, "' not found. Download the data archive from Zenodo ",
       "and unzip it at the root of this repository (see README.md).")

# the point cloud may be .laz or .las, the voxel file gzipped or not
first_existing <- function(paths) {
  p <- paths[file.exists(paths)]
  if (!length(p)) stop("None of these files exists: ", paste(paths, collapse = ", "))
  p[1]
}

list(
  # --- input files -------------------------------------------------------------
  tar_target(file_bbox,     file.path(demo_dir, paste0(plot_name, "_bbox.txt")),     format = "file"),
  tar_target(file_dtm,      file.path(demo_dir, paste0(plot_name, "_dtm.tif")),      format = "file"),
  tar_target(files_subplot, list.files(file.path(demo_dir, "subplots"), full.names = TRUE),
             format = "file"),
  tar_target(file_las,      first_existing(file.path(demo_dir, paste0(plot_name, "_clean", c(".laz", ".las")))),
             format = "file"),
  tar_target(file_vox,      first_existing(file.path(demo_dir, c("vox_merge.txt.gz", "vox_merge.txt"))),
             format = "file"),
  tar_target(rb,            file.path(demo_dir, "dart", paste0(plot_name, "_rb_raw.rdata")),
             format = "file"),

  # --- processing chain --------------------------------------------------------
  tar_target(bbox, {file_bbox; get_bbox(demo_dir, plot_name)}),
  tar_target(dtm, {file_dtm; get_dtm(demo_dir, plot_name, bbox, out_dir)}, format = "file"),
  tar_target(subplot_extent, {files_subplot; get_subplot_extent(demo_dir)}),
  tar_target(rb_norm, normalize_rb(plot_name, rb_path = rb, dtm = dtm, out_dir = out_dir),
             format = "file"),
  tar_target(voxnorm, get_pad(file_vox, plot_name, out_dir), format = "file"),
  tar_target(pc_norm, get_pc_norm_clean(file_las, plot_name, bbox, dtm, out_dir),
             format = "file"),

  # --- metrics (same settings as for the 19 plots of the paper) ----------------
  tar_target(metric3d_df,
             get_complexity(pc_norm, rb_norm, voxnorm, bbox, subplot_extent,
                            plot_name = plot_name, sliced = TRUE, nstrat = 4)),
  tar_target(metric3d_df_unsliced,
             get_complexity(pc_norm, rb_norm, voxnorm, bbox, subplot_extent,
                            plot_name = plot_name, sliced = FALSE,
                            slice_low = 0, slice_up = 4)),
  tar_target(H_ext,
             get_Hext(rb_norm, pc_norm, voxnorm, subplot_extent, bbox, plot_name,
                      targets        = c(0.5, 0.9),
                      z_ref          = 4.5,
                      voxel_size     = 0.25,
                      pad_unit       = c("density"),
                      smooth_columns = TRUE,
                      touches        = FALSE,
                      return_rasters = FALSE)),
  tar_target(gini,
             get_light_metrics(rb_norm, voxnorm, bbox, subplot_extent, plot_name,
                               vox_size       = 0.25,
                               horiz_low      = 0,      # m
                               horiz_up       = 4.5,    # m
                               k              = 0.5,    # extinction big-leaf
                               z_top          = NULL,   # m, NULL = from the PAD
                               keep_profiles  = FALSE,
                               pad_is_density = TRUE)),
  tar_target(tls_metrics_demo,
             build_tls_metrics(metric3d_df, metric3d_df_unsliced, H_ext, gini)),

  # --- check against the tables used in the paper -------------------------------
  tar_target(file_tables_paper,
             file.path("data/analysis",
                       c("metric3d_all.csv", "metric3d_all_unsliced.csv",
                         "H_ext_all.csv", "gini_all.csv")),
             format = "file"),
  tar_target(check_vs_paper,
             compare_demo_to_paper(tls_metrics_demo, file_tables_paper, plot_name)),

  # --- example figure: 3D light distribution, xy sum and vertical profile -------
  tar_target(fig_light_3d, plot_light_3d(rb_norm, rb, tls_metrics_demo, plot_name)),
  tar_target(file_fig_light_3d,
             save_fig(fig_light_3d, "mainfig_light3d_GER34", 21, 9, scale = 1.2),
             format = "file")
)
