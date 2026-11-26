# regeneration-complexity-paper

Code to reproduce the analyses and figures of:

> **[Paper title]** — Baranger A. et al. ([journal], [year]). DOI: [paper DOI]

Code: this repository (archived on Zenodo, DOI: [code DOI]).
Data: Zenodo, DOI: [data DOI].

## Quick start

1. Clone this repository.
2. Download the data archive from Zenodo ([data DOI]) and unzip it at the root
   of the repository, so that you get a `data/` folder containing `analysis/`
   and `demo_GER34/` (see [data/README.md](data/README.md)).
3. In R, from the root of the repository:

```r
# all statistics and figures of the paper (except the 3D light example)
targets::tar_make()

# processing chain demo on plot GER34 + 3D light example figure
Sys.setenv(TAR_PROJECT = "demo")
targets::tar_make()
Sys.setenv(TAR_PROJECT = "main")
```

Figures are written to `figures/` (png and pdf). Any result can be read with
`targets::tar_read(<target name>)`, for instance `tar_read(varpart)`.

## Repository structure

```
├── _targets.R           # main pipeline: statistics and figures from data/analysis/
├── _targets_demo.R      # demo pipeline: TLS + light processing for plot GER34
├── _targets.yaml        # declares the two pipelines ("main" and "demo")
├── R/
│   ├── functions_processing.R  # TLS, AMAPVox and DART processing; survey metrics
│   ├── functions_dataformat.R  # assembling the analysis tables
│   ├── functions_analysis.R    # PCA, bootstrapped effects, variance partitioning
│   ├── functions_plots.R       # figures
│   └── functions_utils.R       # variable metadata, helpers, save_fig()
└── data/                # from Zenodo (not tracked by git)
```

## Two levels of reproducibility

**Main pipeline (`_targets.R`).** It starts from the derived tables in
`data/analysis/`: the TLS and light metrics of the 19 plots and their subplots,
the regeneration metrics and classes, and the plot-level adult tree metrics.
It reproduces every statistic and figure of the paper except the 3D light
example.

**GER34 demo (`_targets_demo.R`).** The raw TLS point clouds and DART
simulations of all plots are too large to distribute; the full set of inputs is
given for one plot, GER34. The demo runs the whole processing chain on it
(height normalisation, PAD, radiative budget, complexity, light extinction and
light heterogeneity metrics), checks the recomputed metrics against the GER34
rows of `data/analysis/` (target `check_vs_paper`), and builds the 3D light
example figure. The extinction step fits one GAM per voxel column and takes a
while.

The demo starts from the DART radiative budget arrays: running DART itself
requires the DART software (https://dart.omp.eu). The DART settings of the
GER34 simulations are given in `data/demo_GER34/dart/settings/`.

The regeneration and adult metrics are computed from the field surveys by
`get_regen_metric_plot()`, `get_regen_metric_subplot()` and `get_adults_2025()`
(in `R/functions_processing.R`). The raw surveys are not distributed; their
outputs are in `data/analysis/`.

## Software

Analyses were run with R [version]. Main packages: targets, dplyr, tidyr,
ggplot2, patchwork, vegan, rdacca.hp, lme4 (main pipeline); lidR, terra, sf,
mgcv (demo). [Exact versions: renv.lock.]

## Licence

Code: [MIT]. Data: see the Zenodo record ([CC-BY 4.0]).
