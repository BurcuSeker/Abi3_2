LSCI Analysis Pipeline for Cerebral Blood Flow

This folder contains MATLAB scripts for analyzing Laser Speckle Contrast Imaging (LSCI) data related to cerebral blood flow.  
The pipeline was developed for studies examining cerebrovascular function and was used, in part, for analyses presented in Figure 7k–l of the associated manuscript.

Sample LSCI data for testing the pipeline are archived on OSF (DOI: https://doi.org/10.17605/OSF.IO/SYZGA).  
These are example datasets intended for running the code, not the complete raw dataset.

---------------------------------------------------------------------

Overview

This pipeline:

- Detects and organizes .dat or raw LSCI imaging files
- Prepares data for ROI definition
- Allows manual ROI definition (with visual QC)
- Computes perfusion time courses
- Aligns data to stimulation epochs
- Produces subject-level and group-level summary plots
- Outputs ROI-level data for downstream statistical analysis

All scripts are modular and can be adapted to different datasets or directory structures.

---------------------------------------------------------------------

Software Requirements

- MATLAB R2023a (pipeline developed and tested)
- Compatible with MATLAB >= R2021b

Required Toolboxes:
- Image Processing Toolbox
- Statistics and Machine Learning Toolbox
- Signal Processing Toolbox (optional)

---------------------------------------------------------------------

Folder Structure

LSCI_Analysis/
+-- data/                # Placeholder folder; full data hosted on OSF
¦   +-- subjects.xlsx    # Example metadata
+-- scripts/             # Run in numerical order
¦   +-- 01_setup_project.m
¦   +-- 02_find_datasets.m
¦   +-- 03_define_ROI_prepare.m
¦   +-- 04_define_ROI_manually.m
¦   +-- 05_average_epochs.m
¦   +-- 06_unblind_QC.m
¦   +-- 07_summarize_results.m
+-- utils/
+-- README.md

---------------------------------------------------------------------

Workflow

1. 01_setup_project.m – setup and parameters
2. 02_find_datasets.m – detects sessions and organizes subjects
3. 03_define_ROI_prepare.m – previews and prepares ROI frames
4. 04_define_ROI_manually.m – interactive ROI definition
5. 05_average_epochs.m – epoch alignment and averaging
6. 06_unblind_QC.m – QC and summary visualization
7. 07_summarize_results.m – exports ROI-level results

---------------------------------------------------------------------

Example Data (Hosted on OSF)

Due to file-size limitations, only sample LSCI data are provided externally.

OSF DOI: https://doi.org/10.17605/OSF.IO/SYZGA

Files include:

- Sample raw LSCI recordings
- Example metadata (subjects_example.xlsx)
- ROI masks and QC outputs
- Instructions for reproducing the analysis workflow

---------------------------------------------------------------------

Data Format Requirements

data/
+-- GroupA/
¦   +-- 221.dat
¦   +-- 222.dat
+-- GroupB/
¦   +-- 154.dat
¦   +-- 916.dat
+-- subjects.xlsx

---------------------------------------------------------------------

Acknowledgements

This pipeline was originally developed for cerebral blood flow studies using LSCI within the context of the Abi3 project.
If you use this code, please cite the associated manuscript once published and the OSF resource:
DOI: https://doi.org/10.17605/OSF.IO/SYZGA
