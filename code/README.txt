# Analysis code

This directory contains all analysis code used for the Abi3 manuscript.
Scripts are organized either as stand-alone figure-specific analyses or
as full analysis pipelines contained in dedicated subdirectories.

---

## Stand-alone Python analysis scripts

Several manuscript figure panels are generated using independent Python
scripts that operate directly on pre-compiled data tables.

These scripts can be run individually and do not require execution of
the full image-processing pipelines.

### Required data file

All stand-alone scripts require the master Excel file:

data/Abi3_data_collate_main_figures.xlsx

This file contains aggregated values for analyses including:
- Plaque diffusivity
- Median and maximum intensity measurements
- Microglia–plaque interaction metrics
- Plaque fragmentation

Ensure this file is available at the specified path before running any
stand-alone script.

### Included scripts

- `Fig3h_Plaque_diffusivity_Int_Median_equal_bin_sizes_manuscript_adjusted.py`  
  Generates bin-size–adjusted median diffusivity curves.

- `Fig3i_Strip_plot_Plaque_diffusivity_Int_Max.py`  
  Creates strip plots for plaque diffusivity (maximum intensities).

- `Fig4e_Microglia_plaque_interaction_plaque_volume_manuscript.py`  
  Analyzes microglia–plaque interaction and plaque-volume metrics.

- `SupplFig5_Plaque_fragmentation_UltimateCodeforPaper_BS.py`  
  Computes and plots plaque fragmentation metrics.

---

## Full analysis pipelines

In addition to the stand-alone scripts, this directory contains several
subfolders implementing complete analysis pipelines. Each pipeline is
self-contained and includes its own README with detailed documentation,
input requirements, and execution steps.

These pipelines include:

- **Arterial amyloid-ß analysis**  
  (`Fig5_c_d_e_arterial_amyloid_beta_analysis/`)  
  Fiji/ImageJ preprocessing and bounding-box ROI extraction followed by
  Python-based quantification.

- **Neuronal activity analysis (calcium imaging)**  
  (`Fig7_e_f_neuronal_activity_analysis/`)  
  End-to-end pipeline including motion correction, denoising, Suite2p
  processing, deconvolution, and evoked ?F/F0 analysis.

- **Vessel diameter analysis during whisker stimulation**  
  (`Fig7h_i_vessel_max_dilation_analysis/`)  
  Fiji-based VasoMetrics processing followed by Python analysis.

- **Laser speckle contrast imaging (LSCI) analysis**  
  (`Fig7_k_l_LSCI_analysis/`)  
  Analysis of LSCI data including ROI definition, quality control, and
  heatmap generation.

Users should refer to the README files within each subdirectory for
pipeline-specific instructions.

---

## Running stand-alone scripts

Stand-alone scripts require Python 3.8 or later.

Run a script directly from the command line, for example:

```bash
python Fig3h_Plaque_diffusivity_Int_Median_equal_bin_sizes_manuscript_adjusted.py
