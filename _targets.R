# =============================================================================
# Main pipeline: every statistic and figure of the paper (except the 3D light
# example, built by the GER34 demo, see _targets_demo.R), from the derived
# tables in data/analysis/.
#
# Run with:  targets::tar_make()
# =============================================================================

library(targets)
tar_source(files = "R")
tar_option_set(packages = c("dplyr", "ggplot2", "tidyr", "readr", "tibble", "purrr"))

data_dir <- "data/analysis"
if (!dir.exists(data_dir))
  stop("Folder '", data_dir, "' not found. Download the data archive from Zenodo ",
       "and unzip it at the root of this repository (see README.md).")

# Read a derived table; the regeneration classes are restored as ordered levels
read_table_csv <- function(path) {
  df <- as.data.frame(readr::read_csv(path, show_col_types = FALSE, guess_max = 1e5))
  if ("reg_category" %in% names(df))
    df$reg_category <- factor(df$reg_category, levels = c("Low", "Medium", "High"))
  df
}

# =============================================================================
# Variable sets used in the figures
# =============================================================================

paper_vars <- list(
  pca_regen  = c("richness", "H", "richness_sapling", "cwm_shade", "abundance", "n_sapling",
                 "Height_increment_mn", "H_height", "empty_gf", "pad_cv", "ri", "fhd","pad_tot"),
  lidar      = c("empty_gf", "pad_tot", "pad_cv", "ri", "fhd"),
  light      = c("lrb_mean", "ext_ref_agg", "rb_cv", "gini_h_rb", "bl_diff_abs", "slope_ref_agg"),
  light_box  = c("lrb_mean", "ext_ref_agg", "rb_cv", "gini_h_rb", "bl_diff_abs", "slope_ref_agg",
                 "padAbove_agg", "padAbove_cv"),
  regen      = c("richness", "richness_sapling", "H", "cwm_shade", "abundance", "n_sapling",
                 "Height_increment_mn", "empty_gf", "H_height", "fhd", "ri", "pad_cv"),
  light_expl = c("lrb_mean", "gini_h_rb", "slope_ref_agg", "bl_diff_abs"),
  adult_expl = c("n_trees_alive", "species_richness_alive", "mean_dbh_alive_cm",
                 "mortality_rate","recruitment_rate", "max_dbh_alive_cm", "rgr_mean",
                 "rgr_sd"),
  variability = c("ext_ref_agg", "slope_ref_agg", "gini_h_rb"),
  vp_adult   = c("species_richness_alive", "mean_dbh_alive_cm","n_trees_alive"),
  vp_light   = c("lrb_mean", "gini_h_rb", "slope_ref_agg"),
  vp_regen   = c("richness", "abundance", "ri"),
  vp_log     = c("abundance"),
  vp_labels  = c(species_richness_alive = "Adult species richness",
                 mean_dbh_alive_cm = "Mean DBH", mean_height_alive_m = "Mean height",
                 lrb_mean = "Radiative budget \nmean (log)", gini_h_rb = "Gini index",
                 slope_ref_agg = "Light profile \nslope at 4.5m",
                 richness = "Richness", abundance = "Abundance", ri = "Complexity",
                 n_trees_alive="Tree number",rgr="Relative growth rate")
)


list(
  # --- input data (derived tables, see data/README_data.md) --------------------
  tar_target(file_metric3d_all,          file.path(data_dir, "metric3d_all.csv"),          format = "file"),
  tar_target(file_metric3d_all_unsliced, file.path(data_dir, "metric3d_all_unsliced.csv"), format = "file"),
  tar_target(file_H_ext_all,             file.path(data_dir, "H_ext_all.csv"),             format = "file"),
  tar_target(file_gini_all,              file.path(data_dir, "gini_all.csv"),              format = "file"),
  tar_target(file_regen_metrics_plot,    file.path(data_dir, "regen_metrics_plot.csv"),    format = "file"),
  tar_target(file_regen_metrics_subplot, file.path(data_dir, "regen_metrics_subplot.csv"), format = "file"),
  tar_target(file_regen_cat,             file.path(data_dir, "regen_cat_plot.csv"),        format = "file"),
  tar_target(file_regen_cat_subplot,     file.path(data_dir, "regen_cat_subplot.csv"),     format = "file"),
  tar_target(file_plot_df_2025,          file.path(data_dir, "adults_plot_2025.csv"),      format = "file"),

  tar_target(metric3d_all,          read_table_csv(file_metric3d_all)),
  tar_target(metric3d_all_unsliced, read_table_csv(file_metric3d_all_unsliced)),
  tar_target(H_ext_all,             read_table_csv(file_H_ext_all)),
  tar_target(gini_all,              read_table_csv(file_gini_all)),
  tar_target(regen_metrics_plot,    list(all = read_table_csv(file_regen_metrics_plot))),
  tar_target(regen_metrics_subplot, list(all = read_table_csv(file_regen_metrics_subplot))),
  tar_target(regen_cat,             read_table_csv(file_regen_cat)),
  tar_target(regen_cat_subplot,     read_table_csv(file_regen_cat_subplot)),
  tar_target(plot_df_2025,          read_table_csv(file_plot_df_2025)),

  # --- format data ------------------------------------------------------------
  tar_target(var_meta, make_var_meta()),
  tar_target(tls_metrics,
             build_tls_metrics(metric3d_all, metric3d_all_unsliced, H_ext_all, gini_all)),
  tar_target(forest_data_plot,
             build_forest_data_plot(regen_metrics_plot, regen_cat, plot_df_2025)),
  tar_target(forest_data_subplot,
             build_forest_data_subplot(regen_metrics_subplot, regen_cat_subplot, plot_df_2025)),

  # --- 1. regeneration structure PCA ------------------------------------------
  tar_target(pca_regen,
             run_pca_regen(tls_metrics, forest_data_plot, forest_data_subplot, regen_cat,
                           paper_vars$pca_regen, paper_vars$lidar, var_meta)),
  tar_target(cor_regen, cor_table(pca_regen$data)),
  tar_target(fig_pca_regen, plot_pca_regen(pca_regen)),
  tar_target(file_fig1,
             save_fig(fig_pca_regen, "mainfig1_PCA_regen_v3", 8.5, 11, scale = 1.2),
             format = "file"),

  # --- 2. light descriptors, plot level ---------------------------------------
  tar_target(pca_light_plot,
             run_pca_light(tls_metrics, forest_data_plot, paper_vars$light, "plot", var_meta)),
  tar_target(cor_light, cor_table(pca_light_plot$data)),
  tar_target(box_light_plot,
             light_box_data(tls_metrics, forest_data_plot, paper_vars$light_box, "plot", var_meta)),
  tar_target(fig_light_plot,
             plot_light_panel(plot_pca_light(pca_light_plot),
                              plot_light_boxes(box_light_plot, kw = kw_by_variable(box_light_plot)))),
  tar_target(file_fig2,
             save_fig(plot_pca_light(pca_light_plot), "mainfig2_PCA_light", 8.5, 11, scale = 1.1),
             format = "file"),
  tar_target(file_fig2.1,
             save_fig( plot_light_boxes(box_light_plot, kw = kw_by_variable(box_light_plot)),
                       "si_lightdist", 16, 9, scale = 1.1),
             format = "file"),

  # --- 3. light effects, plot level -------------------------------------------
  tar_target(light_effect_plot,
             build_light_effect_data(tls_metrics, forest_data_plot,
                                     c(paper_vars$regen, paper_vars$light_expl), "plot")),
  tar_target(boot_light_plot,
             boot_effects(light_effect_plot, paper_vars$regen, paper_vars$light_expl, B = 1000)),
  tar_target(fig_light_eff,
             plot_effects(boot_light_plot, var_meta, paper_vars$regen,
                          paper_vars$light_expl, drop = "bl_diff_abs")),
  tar_target(file_fig3,
             save_fig(fig_light_eff, "mainfig3_light_eff", 16, 9, scale = 1.2),
             format = "file"),

  # --- 3b. light effects on species/individuals ratio, plot level (table only) --
  tar_target(tab_light_sp_ratio,
             light_effect_sp_ratio(tls_metrics, forest_data_plot,
                                   paper_vars$light_expl, B = 1000)),

  # --- 4. subplot level --------------------------------------------------------
  tar_target(pca_light_subplot,
             run_pca_light(tls_metrics, forest_data_subplot, paper_vars$light, "subplot", var_meta)),
  tar_target(box_light_subplot,
             light_box_data(tls_metrics, forest_data_subplot, paper_vars$light_box, "subplot", var_meta)),
  tar_target(fig_light_subplot,
             plot_light_panel(plot_pca_light(pca_light_subplot, point_size = 1.5),
                              plot_light_boxes(box_light_subplot,
                                               cld = cld_by_variable(box_light_subplot)))),
  tar_target(light_effect_subplot,
             build_light_effect_data(tls_metrics, forest_data_subplot,
                                     c(paper_vars$regen, paper_vars$light_expl), "subplot")),
  tar_target(boot_light_subplot,
             boot_effects(light_effect_subplot, paper_vars$regen, paper_vars$light_expl,
                          B = 1000, random = "plot", cluster_boot = FALSE)),
  tar_target(fig_light_eff_subplot,
             plot_effects(boot_light_subplot, var_meta, paper_vars$regen,
                          paper_vars$light_expl, drop = "bl_diff_abs")),
  tar_target(file_fig4,
             save_fig(fig_light_eff_subplot, "si_light_eff_subplot", 13, 9, scale = 1.2),
             format = "file"),

  # --- 5. temporal vs spatial variability ---------------------------------------
  tar_target(light_variability, compute_light_variability(tls_metrics, paper_vars$variability)),
  tar_target(fig_variability, plot_variability(light_variability, var_meta)),
  tar_target(file_fig5.1,
             save_fig(fig_variability,
                       "si_tempspatvar", 16, 9, scale = 1),
             format = "file"),

  # --- 6. adult structure effects -----------------------------------------------
  tar_target(adult_effect,
             prep_data(tls_metrics, forest_data_plot,
                       id_cols = c(paper_vars$regen, paper_vars$adult_expl), plot_level = "plot")),
  tar_target(boot_adult,
             boot_effects(adult_effect, paper_vars$regen, paper_vars$adult_expl, B = 1000)),
  tar_target(fig_adult_eff,
             plot_effects(boot_adult, var_meta, paper_vars$regen,
                          paper_vars$adult_expl, lw = c(0.9, 1.5))),
  tar_target(file_fig6,
             save_fig(fig_adult_eff, "si_adult_eff", 16, 9, scale = 1.2),
             format = "file"),

  # --- 7. variance partitioning --------------------------------------------------
  tar_target(varpart,
             run_varpart(tls_metrics, forest_data_plot,
                         adult_vars = paper_vars$vp_adult, light_vars = paper_vars$vp_light,
                         regen_vars = paper_vars$vp_regen, log_vars = paper_vars$vp_log,
                         n_perm = 999, n_perm_hp = 999)),
  tar_target(fig_varpart_venn, plot_varpart_venn(varpart)),
  tar_target(file_fig7.1,
             save_fig(fig_varpart_venn, "si_venndiag", 8.5, 6.5, scale = 1.2),
             format = "file"),
  tar_target(fig_varpart_uni,  plot_varpart_univariate(varpart, paper_vars$vp_labels)),
  tar_target(file_fig7,
             save_fig(fig_varpart_uni, "mainfig7_varpart_v3", 16, 9, scale = 1.2),
             format = "file"),
  tar_target(fig_rda_triplot,  plot_rda_triplot(varpart, paper_vars$vp_labels)),
  tar_target(file_fig7.2,
             save_fig(fig_rda_triplot, "si_triplot", 8.5, 9, scale = 1.2),
             format = "file")
)
