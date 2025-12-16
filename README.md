# Abi3 manuscript

This repository contains analysis code used for the Abi3 manuscript,
including image-derived quantifications, data aggregation, and
downstream analyses for main and supplementary figures.

The code is organized primarily by figure to facilitate transparency,
traceability, and reproducibility.

---

## Repository structure

### `code/`

Analysis scripts and pipelines organized by figure or analysis module.

Standalone scripts (e.g. `.py`) correspond to specific main or
supplementary figure panels. More complex analyses are contained in
dedicated subfolders, each with its own README describing inputs,
processing steps, and outputs.

Key subdirectories include:

- `Fig5_c_d_e_arterial_amyloid_beta_analysis/`  
  Arterial amyloid-β image analysis pipeline.

- `Fig7_e_f_neuronal_activity_analysis/`  
  Neuronal activity analyses associated with Figure 7e–f.

- `Fig7_h_i_vessel_max_dilation_analysis/`  
  Vessel dilation analyses.

- `Fig7_k_l_LSCI_analysis/`  
  Laser speckle contrast imaging (LSCI) analyses.

Additional figure-specific analyses are implemented as standalone Python
scripts within this directory.

A brief overview of the code directory is provided in:
- `code/README.md`
- `code/README.txt`

---

### `data/`

This directory contains compiled data tables used for downstream
analysis and figure generation.

- `Abi3_data_collate_main_figures.xlsx`  
  Compiled data for main figures.

- `Suppl_data.xlsx`  
  Compiled data for supplementary figures.

Raw imaging data are not stored in this repository due to size
constraints.

---

### `Abi3_github.Rproj`

R project file used for project organization and environment management.

---

### `README.md`

This file. Provides a high-level overview of the repository.

---

## Data availability

Raw and large imaging datasets associated with this manuscript are
hosted externally due to size limitations.

Links to external data repositories (e.g. OSF) are provided in the
manuscript and, where relevant, in subfolder-level README files within
the `code/` directory.

---

## Reproducibility notes

- Analyses were developed using Python-based workflows and
  image-processing tools (e.g. Fiji / ImageJ where applicable).
- Figure-specific subfolders contain detailed documentation describing
  required inputs and expected outputs.
- Users are encouraged to begin with the README files located in each
  analysis subdirectory.

---

## Contact

For questions related to the analysis or code organization, please
contact the manuscript authors.
