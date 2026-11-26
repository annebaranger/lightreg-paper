# Data

This folder is not tracked by git. Download the data archive from Zenodo
([data DOI]) and unzip it here, so that it contains:

```
data/
├── analysis/                    # derived tables, read by _targets.R
│   ├── metric3d_all.csv           # TLS / light metrics per 1 m height slice (0.5-4.5 m)
│   ├── metric3d_all_unsliced.csv  # same metrics on the whole 0-4 m layer
│   ├── H_ext_all.csv              # light extinction profile and PAD metrics
│   ├── gini_all.csv               # light heterogeneity (Gini) and big-leaf deviation
│   ├── regen_metrics_plot.csv     # regeneration metrics, plot level
│   ├── regen_metrics_subplot.csv  # regeneration metrics, subplot level
│   ├── regen_cat_plot.csv         # regeneration class (Low / Medium / High), plot level
│   ├── regen_cat_subplot.csv      # regeneration class, subplot level
│   └── adults_plot_2025.csv       # adult tree metrics, 2025 inventory, plot level
└── demo_GER34/                  # inputs of the GER34 demo, read by _targets_demo.R
    ├── GER34_bbox.txt             # plot bounding box (as used in AMAPVox)
    ├── GER34_dtm.tif              # digital terrain model
    ├── subplots/                  # subplot point clouds (used for their outlines)
    ├── GER34_clean.laz            # cleaned TLS point cloud, clipped to the bounding box
    ├── vox_merge.txt.gz           # AMAPVox voxelisation (0.25 m)
    └── dart/
        ├── GER34_rb_raw.rdata     # DART 3D radiative budget, one array per simulated hour
        └── settings/              # DART simulation settings (xml), one folder per hour
```

The Zenodo archive has its own `README_data.md` describing every column.
