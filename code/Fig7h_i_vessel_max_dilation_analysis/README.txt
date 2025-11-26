# Vessel Diameter Analysis for Whisker Stimulation Experiments

This folder contains the full workflow for quantifying **cerebral vessel diameter changes** during whisker stimulation.  
The analysis is performed in **two sequential steps**:

1. **Vessel diameter extraction in Fiji/ImageJ using VasoMetrics**  
2. **Trial-based dilation analysis using Python**  
   (baseline normalization, % dilation, time-to-peak, time-to-10%, summary plots)

> **Important:**  
> Raw vasomotion videos **must always be processed through VasoMetrics first**  
> before running the Python analysis script in this folder.

Example raw vessel videos are available on OSF:  
🔗 **https://doi.org/10.17605/OSF.IO/SYZGA**

---

# 1. Workflow Overview

### **Input**
- Time-series imaging of cortical vessels (e.g., two-photon line/area scans, widefield imaging)
- TIFF stacks or ImageJ-readable formats

### **Step 1 — Fiji/ImageJ (VasoMetrics)**
- User draws one **centerline (“through-line”)** along the vessel  
- VasoMetrics generates **multiple perpendicular cross-lines**  
- For each frame and cross-line, VasoMetrics computes **vessel diameter using FWHM**  
- Exports a **Results table** containing:
  - `Frame`
  - `Mean` (mean diameter across all cross-lines)
  - `SD`
  - `Line 1 … Line N` (diameter per cross-line)

Export each VasoMetrics output table as **CSV**.

### **Step 2 — Python Script (whisker stimulation analysis)**

Filename:
```
051224_WorkingWhiskerStimScriptWithPictures_WithAverageTimetoDilation_timeto10-.py
```

The Python script performs:
- Smoothing and filtering
- Baseline normalization (% dilation)
- Automatic epoch segmentation (whisker stimulation)
- Computation of:
  - Median % dilation  
  - Maximum % dilation  
  - Time to peak  
  - Mean time to 10% of max dilation  
- Optional automated ROI snapshot export (baseline, post-baseline, max dilation)
- Outputs:
  - Excel files with quantitative metrics
  - PNG plots of normalized diameter traces and summary statistics
  - Optional extracted JPEG/TIFF images via Fiji/Jython

---

# 2. Requirements

## **2.1 Fiji / ImageJ Requirements**
- ImageJ or **Fiji** (recommended)
- **VasoMetrics.ijm** macro (included here)

### Citation (VasoMetrics)
If you use VasoMetrics, please cite:

**McDowell KP, Berthiaume AA, Tieu T, Hartmann DA, Shih AY.**  
*VasoMetrics: unbiased spatiotemporal analysis of microvascular diameter in multiphoton imaging applications.*  
Quantitative Imaging in Medicine and Surgery (2021).  
https://doi.org/10.21037/qims-20-920

### Recommended setup
- Set the imaging scale via **Analyze → Set Scale…**  
  Ensures VasoMetrics exports diameters in µm.

---

## **2.2 Python Requirements**
- Python 3.x

Required packages:
```
pandas
numpy
scipy
matplotlib
seaborn
openpyxl
```

Install:
```
pip install pandas numpy scipy matplotlib seaborn openpyxl
```

### Optional (for ROI image extraction)
- Fiji installed
- Jython 2.7.x
- Valid paths to `ij.jar` and BioFormats inside the script (check script header)

---

# 3. Step-by-Step Instructions

## **3.1 Step 1 — Extract Diameters with VasoMetrics (in Fiji)**

1. Open your raw vessel TIFF stack in **Fiji**  
2. Set the image scale (**Analyze → Set Scale…**)  
3. Load `VasoMetrics.ijm` via **Plugins → Macros → Run…**  
4. Draw a **centerline** along the vessel  
5. When prompted, set:
   - number of cross-lines  
   - spacing  
   - length  
6. Run VasoMetrics  
7. Export the **Results** table as CSV  
   Example:
   ```
   mouse01_vessel1_VasoMetrics.csv
   ```

Repeat for each vessel and each mouse.

---

## **3.2 Step 2 — Analyze Dilation (Python)**

### Run the script:
```
python 051224_WorkingWhiskerStimScriptWithPictures_WithAverageTimetoDilation_timeto10-.py
```

### The GUI will ask for:
- CSV file (VasoMetrics export)  
- Frame interval / frame rate  
- Smoothing window  
- Baseline window  
- Stimulation window  
- Filtering options  

### The script outputs:
- **Excel** file with all computed metrics  
- **PNG** plots of diameter traces and summary graphs  
- (Optional) **ROI images** extracted in Fiji (baseline, post-baseline, peak dilation)

---

# 4. Outputs

You will obtain:

### **Excel Files**
- Baseline values
- Peak dilation
- % change
- Time-to-peak
- Time-to-10% (mean across trials)
- Per-frame normalized diameter traces

### **Figures (PNG)**
- Normalized trace plot
- Summary dilations
- Per-trial analysis plots

### **Optional ROI Images**
- Baseline TIFF/JPEG  
- Early dilation  
- Max dilation timepoint  

---

# 5. OSF Example Data

Example raw vasculature TIFF videos and example VasoMetrics output tables are available at:

🔗 **OSF Dataset:** https://doi.org/10.17605/OSF.IO/SYZGA

These data allow users to reproduce the full workflow (Fiji → VasoMetrics → Python).

---

# 6. Citing This Pipeline

When using this analysis pipeline, please cite:

### **VasoMetrics (for diameter extraction)**  
McDowell KP et al., 2021 (see Section 2.1)

### **This repository**  
If you use the whisker dilation Python analysis (this folder),  
please cite the repository and acknowledge:

**“Vessel-diameter whisker stimulation analysis script developed as part of the Abi3 project.”**

---

# END OF DOCUMENT
