Stand-Alone Python Analysis Scripts
===================================

This folder contains independent Python scripts used to generate
specific manuscript figure panels directly from pre-compiled data.

------------------------------------------------------------
Required Data File
------------------------------------------------------------

All scripts in this directory require the master Excel file:

    data/All_data_compiled/Abi3_data_collate_main_figures.xlsx

This file contains aggregated values for:
- Plaque diffusivity
- Median intensity analyses
- Microglia–plaque interaction metrics
- Plaque fragmentation

Make sure this Excel file is located in the path above BEFORE running
any script.

------------------------------------------------------------
Scripts Included (Standalone Analysis)
------------------------------------------------------------

• Fig3b_Plaque_diffusivity_Int_Median_equal_bin_sizes_manuscript_adjusted.py  
    Generates bin-size–adjusted median diffusivity curves.

• Fig3i_Strip_plot_Plaque_diffusivity_Int_Max.py  
    Creates strip plots for plaque diffusivity (maximum intensities).

• Fig4e_Microglia_plaque_interaction_plaque_volume_manuscript.py  
    Analyzes microglia–plaque interaction and plaque-volume metrics.

• SupplFig5_Plaque_fragmentation_UltimateCodeforPaper_BS.py  
    Computes and plots plaque fragmentation metrics.

------------------------------------------------------------
Other Analysis Pipelines in This Repository
------------------------------------------------------------

In addition to these stand-alone scripts, this repository contains
several **subfolders with full analysis pipelines**, each with its
own dedicated README describing usage, requirements, and workflow.

These include:

• LSCI (Laser Speckle Contrast Imaging) analysis pipeline  
  ? MATLAB-based workflow with ROI definition, epoch averaging,  
     QC, and heatmap generation.  
  ? See: `LSCI_Analysis/README.md`

• Neuronal Activity Analysis (Calcium Imaging – Suite2p + Python)  
  ? Complete pipeline from raw TIFF ? NoRMCorre ? DeepCAD ?  
     Suite2p ? deconvolution ? evoked ?F/F0 analysis.  
  ? See: `Fig7_neuronal_activity_analysis/README.md`

• Arterial Amyloid-ß Analysis (Fiji macros + Python)  
  ? Preprocessing + bounding-box ROI extraction for arterial Aß  
     quantification.  
  ? See: `Fig5_c_d_e_arterial_amyloid_beta_analysis/README.md`

• Vessel Diameter Analysis for Whisker Stimulation  
  ? VasoMetrics (Fiji) + Python dilation analysis.  
  ? See: `Vessel_Diameter_Analysis/README.md`

Each pipeline is self-contained and includes all instructions needed
to run the analysis end-to-end.

------------------------------------------------------------
How to Run the Stand-Alone Scripts
------------------------------------------------------------

Use Python 3.8 or later. Run any script directly:

    python script_name.py

Example:

    python Fig3b_Plaque_diffusivity_Int_Median_equal_bin_sizes_manuscript_adjusted.py

Each script automatically loads:

    data/All_data_compiled/Abi3_data_collate_main_figures.xlsx

If you move this Excel file, update the `file_path` variable at the
top of the script you are running.

------------------------------------------------------------
Dependencies
------------------------------------------------------------

Required Python packages:

    numpy
    pandas
    matplotlib
    seaborn
    scipy

Install them with:

    pip install numpy pandas matplotlib seaborn scipy

------------------------------------------------------------
Notes
------------------------------------------------------------

• These scripts operate ONLY on aggregated Excel data  
  (no Fiji, Suite2p, or LSCI processing is required).

• All outputs (plots, Excel files, etc.) are generated in the script's
  directory unless otherwise specified.

------------------------------------------------------------
END OF DOCUMENT
------------------------------------------------------------
