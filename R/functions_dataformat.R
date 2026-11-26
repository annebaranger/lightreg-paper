#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#### SCRIPT INTRODUCTION ####
#
#' @name functions_dataformat.R  
#' @description R script containing all functions relative to data
#               processing
#' @author Anne Baranger
#
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# =============================================================================
# Building the analysis tables
# =============================================================================

#' Bind all tls metrics
build_tls_metrics <- function(metric3d_all, metric3d_all_unsliced, H_ext_all, gini_all) {
  rbind(metric3d_all, metric3d_all_unsliced) %>%
    left_join(H_ext_all, by = c("plot", "subplot", "time")) %>%
    left_join(gini_all,  by = c("plot", "subplot", "time")) %>%
    mutate(lrb_mean = log(rb_mean))
}

#' Bind all forest metrics at the plot level
build_forest_data_plot <- function(regen_metrics_plot, regen_cat, plot_df) {
  regen_metrics_plot$all %>%
    left_join(regen_cat) %>%
    left_join(plot_df) %>%
    mutate(across(c(richness_sapling, n_sapling), ~ tidyr::replace_na(.x, 0)),
           subplot = "plot")
}


#' Bind all forest metrics at the subplot level
build_forest_data_subplot <- function(regen_metrics_subplot, regen_cat_subplot, plot_df) {
  regen_metrics_subplot$all %>%
    left_join(regen_cat_subplot) %>%
    left_join(plot_df) %>%
    unique() %>%
    mutate(across(c(richness_sapling, n_sapling), ~ tidyr::replace_na(.x, 0)))
}

# Table used by the light-effect models (slope sign flipped as in the original)
build_light_effect_data <- function(tls_metrics, forest_data, vars, plot_level) {
  prep_data(tls_metrics, forest_data, vars, plot_level = plot_level, t = 12, s = 0, tg = 0.9) %>%
    mutate(slope_ref_agg = -slope_ref_agg)
}

# Long, scaled table for the light boxplots
light_box_data <- function(tls_metrics, forest_data, vars, plot_level, var_meta) {
  prep_data(tls_metrics, forest_data, c(vars, "reg_category"),
            plot_level = plot_level, t = 12, s = 0) %>%
    tidyr::pivot_longer(-c(plot, subplot, reg_category)) %>%
    filter(!is.na(reg_category)) %>%
    mutate(name = factor(name, levels = vars),
           reg_category = factor(reg_category)) %>%
    group_by(name) %>%
    mutate(value = as.numeric(scale(value))) %>%
    ungroup() %>%
    left_join(var_meta, by = c("name" = "variable")) %>%
    arrange(name) %>%
    mutate(label = forcats::fct_inorder(fix_cross_labels(label, as.character(name))),
           type  = if_else(type == "PAD", "Plant area density\n distribution", type))
}

# =============================================================================
# GER34 demo: compare the recomputed metrics with the tables used in the paper
# =============================================================================

#' Compare the TLS/light metrics recomputed by the demo with the GER34 rows of
#' the distributed tables. Returns, for each numeric variable, the largest
#' relative difference and the number of rows where only one value is missing;
#' warns if any variable differs by more than `tol`.
#' @param tls_demo output of build_tls_metrics() on the demo targets
#' @param paper_files paths of metric3d_all, metric3d_all_unsliced, H_ext_all and gini_all (csv)
#' @param plot_name plot of the demo
#' @param tol tolerance on the relative difference
compare_demo_to_paper <- function(tls_demo, paper_files, plot_name, tol = 1e-6) {
  rd <- function(f) {
    d <- as.data.frame(readr::read_csv(f, show_col_types = FALSE, guess_max = 1e5))
    d[d$plot == plot_name, , drop = FALSE]
  }
  paper <- build_tls_metrics(rd(paper_files[1]), rd(paper_files[2]),
                             rd(paper_files[3]), rd(paper_files[4]))
  demo  <- as.data.frame(tls_demo)

  keys <- intersect(c("plot", "subplot", "time", "slice_num", "target"), names(paper))
  ord  <- function(d) d[do.call(order, unname(as.list(d[keys]))), , drop = FALSE]
  paper <- ord(paper)
  demo  <- ord(demo)
  if (nrow(paper) != nrow(demo) ||
      !isTRUE(all.equal(demo[keys], paper[keys], check.attributes = FALSE)))
    stop("The demo and the paper tables do not have the same plot/subplot/time/slice rows")

  num <- intersect(names(paper)[vapply(paper, is.numeric, logical(1))], names(demo))
  num <- setdiff(num, keys)
  out <- do.call(rbind, lapply(num, function(v) {
    a  <- demo[[v]]
    b  <- paper[[v]]
    ok <- is.finite(a) & is.finite(b)
    data.frame(variable     = v,
               max_rel_diff = if (any(ok)) max(abs(a[ok] - b[ok]) / pmax(abs(b[ok]), 1e-8)) else 0,
               n_na_mismatch = sum(is.finite(a) != is.finite(b)))
  }))

  bad <- out[out$max_rel_diff > tol | out$n_na_mismatch > 0, ]
  if (nrow(bad)) {
    warning("Demo metrics differ from the paper tables for: ",
            paste(bad$variable, collapse = ", "))
  } else {
    message("All ", nrow(out), " recomputed metrics of ", plot_name,
            " match the paper tables (relative tolerance ", tol, ").")
  }
  out
}
