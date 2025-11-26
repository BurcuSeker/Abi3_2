# LSCI Analysis Pipeline for Cerebral Blood Flow  
MATLAB-based pipeline for processing **Laser Speckle Contrast Imaging (LSCI)** recordings of cerebral blood flow.  
Used in part for analyses shown in **Figure 7k–l** of the associated manuscript.

This README contains:

- Overview of the pipeline  
- Software requirements  
- Repository structure  
- Data organization rules  
- Full HOW-TO-USE instructions  
- OSF example dataset link  
- Script-by-script description (01 → 07)  

---

# 🧭 1. Overview

This pipeline processes raw LSCI `.dat` recordings into:

- Perfusion time courses  
- ROI-based responses  
- Averaged stimulation-epoch traces  
- Heatmaps and QC metrics  
- Group-level summaries  
- Publication-ready figures  

The workflow includes:

1. Detecting and organizing raw `.dat` recordings  
2. Preparing and drawing ROIs  
3. Extracting perfusion time series  
4. Segmenting stimulation epochs  
5. Averaging across episodes  
6. QC and unblinding  
7. Final summary + statistics exports  

All steps are fully reproducible via MATLAB scripts inside this repository.

---

# 🧰 2. Software Requirements

### MATLAB Version
- **MATLAB R2023a** (development version)  
- Compatible with **R2021b–R2024a**

### Required Toolboxes
- **Image Processing Toolbox**  
- **Statistics and Machine Learning Toolbox**  
- **Signal Processing Toolbox** (optional, used for filtering & epoch logic)

No external packages or compiled add-ons are needed.

---

# 📁 3. Repository Structure

```
LSCI_Analysis/
│
├── data/
│   └── subjects.xlsx                 # Metadata template
│
├── scripts/                          # RUN SCRIPTS IN ORDER
│   ├── 01_setup_project.m
│   ├── 02_find_datasets.m
│   ├── 03_define_ROI_prepare.m
│   ├── 04_define_ROI_manually.m
│   ├── 05_average_epochs.m
│   ├── 06_unblind_QC.m
│   └── 07_summarize_results.m
│
├── utils/                            # Helper functions
│
└── README.md                         # You are here
```

---

# 📂 4. Data Organization

Before running the pipeline, your LSCI data must follow this structure:

```
data/
│
├── GroupA/
│    ├── 221.dat
│    ├── 222.dat
│
├── GroupB/
│    ├── 154.dat
│    ├── 916.dat
│
└── subjects.xlsx
```

### **Raw files**  
- `.dat` = raw LSCI speckle recordings  
- Each file = one imaging session

### **subjects.xlsx must contain**
- Subject ID  
- Experimental group  
- Filename  
- Frame rate (fps)  
- (Optional) stimulation timing  
- (Optional) notes / exclusions  

---

# 🧪 5. Example / Test Data (Hosted on OSF)

Example raw LSCI data are too large for GitHub and are hosted on OSF:

### 🔗 **OSF Dataset:** https://doi.org/10.17605/OSF.IO/SYZGA

The OSF project contains:

- Example `.dat` files (mouse recordings)  
- Metadata file `subjects_example.xlsx`  
- Example ROI masks  
- Example averaged outputs  

### To use OSF example data:
1. Download the folders from OSF  
2. Place them inside your `data/` directory:

```
data/
│
├── example_data/
│   ├── mouse01/
│   ├── mouse02/
│
└── subjects_example.xlsx
```

3. Run the pipeline normally (scripts 01–07)

---

# 🚀 6. FULL HOW-TO-USE GUIDE  
*(Integrated from HOW_TO_USE.txt — :contentReference[oaicite:0]{index=0})*

The pipeline consists of **seven scripts** that must be executed **in numerical order**.

---

## ✅ **Step 1 — 01_setup_project.m**

Initializes the entire project.

### What it does
- Defines all paths (root, scripts, utils, data, results, QC)  
- Adds folders to MATLAB path  
- Loads or defines groups  
- Sets global parameters (fps, windows, QC settings)

### You may need to edit:
- Your top-level repo path  
- Group names  
- Default frame rate

### Run:
```matlab
run('scripts/01_setup_project.m')
```

---

## ✅ **Step 2 — 02_find_datasets.m**

Searches the `data/` folder and builds a structured subject table.

### What it does
- Recursively finds `.dat` files  
- Extracts group names from folder names  
- Updates or creates `subjects.xlsx`

### Run:
```matlab
run('scripts/02_find_datasets.m')
```

---

## ✅ **Step 3 — 03_define_ROI_prepare.m**

Prepares each dataset for ROI selection.

### What it does
- Loads subject table  
- Loads raw data previews  
- Displays cranial window for QC  
- Allows definition of **global round ROI** (cranial window mask)  

### Stimulation logic:
- Each recording has **five whisker stimulation episodes**  
- Script automatically selects the **middle 20 s** of each episode  
  - avoids onset artifacts  
  - avoids offset decay  
  - focuses on steady-state response  

### Run:
```matlab
run('scripts/03_define_ROI_prepare.m')
```

---

## ✅ **Step 4 — 04_define_ROI_manually.m**

Manual ROI definition per dataset.

### What you do
- Draw polygon or circle ROIs inside cranial window  
- Save ROI masks (`.mat`)  
- ROIs are used for all downstream analyses

### Run:
```matlab
run('scripts/04_define_ROI_manually.m')
```

---

## ✅ **Step 5 — 05_average_epochs.m**

Extracts and averages stimulation episodes.

### What it does
For each subject:

- Loads ROI masks  
- Extracts 5 × 20 s episodes  
- Computes time courses  
- Averages episodes → **subject-level mean trace**

### Run:
```matlab
run('scripts/05_average_epochs.m')
```

---

## ✅ **Step 6 — 06_unblind_QC.m**

Handles group unblinding + QC visualization.

### What it does
- Links group identity to each subject  
- Plots:
  - ROI time courses  
  - Per-episode and per-subject averages  
  - QC flags  

### Run:
```matlab
run('scripts/06_unblind_QC.m')
```

---

## ✅ **Step 7 — 07_summarize_results.m**

Generates final outputs.

### Output includes:
- Mean group time courses  
- Heatmaps (episode-level & subject-level)  
- Statistics tables (.csv / .mat)  
- Publication-ready plots  

### Run:
```matlab
run('scripts/07_summarize_results.m')
```

---

# 🎯 7. Final Outputs

After running scripts 01 → 07, the following folders will appear:

```
results/
│   ├── group_timecourses/
│   ├── subject_averages/
│   ├── heatmaps/
│   └── statistics/
│
QC/
    ├── window_previews/
    ├── ROI_drawings/
    └── episode_checks/
```

You will obtain:

- ROI masks  
- Per-episode signals  
- Subject averages  
- Group-level averages  
- Heatmaps  
- QC plots  
- Statistical tables  

---
# 📑 Citation & Attribution

The LSCI analysis pipeline provided in this repository is based on the  
**investigator-independent MATLAB analysis tool originally developed by  
Dr. Benno Gesierich**, as published in:

**Seker, F. B., Fan, Z., Gesierich, B., Gaubert, M., Sienel, R. I., & Plesnila, N. (2021).**  
*Neurovascular reactivity in the aging mouse brain assessed by laser speckle contrast imaging and 2-photon microscopy: Quantification by an investigator-independent analysis tool.*  
**Frontiers in Neurology, 12, 745770.**  
https://doi.org/10.3389/fneur.2021.745770  

# 🙌 Acknowledgements

This analysis pipeline was developed for LSCI cerebral blood-flow studies within the **Abi3** project.  
If you use or adapt this code, please cite the associated manuscript once published.

---

# END OF DOCUMENT
