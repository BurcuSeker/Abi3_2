# Arterial Aβ Analysis Pipeline (Fiji / ImageJ)

This directory contains the full workflow used to quantify arterial amyloid-β (Aβ)
deposition from multichannel fluorescence microscopy images (Figure 5c–e).

The analysis comprises two sequential steps:

1. **Preprocessing of multichannel images**  
   → `Fig5_c_d_e_Preprocessing_ArterialAbeta.ijm`

2. **Arterial ROI detection and Aβ quantification**  
   → `Fig5_c_d_e_BoundingBoxer_ArterialAbeta.ijm`

**OSF sample data (example input images):**  
<https://doi.org/10.17605/OSF.IO/SYZGA>

---

## 1. Overview

**Input**

- Multichannel `.tif` images containing at least:
  - α-SMA (arterial smooth muscle marker)
  - Aβ (amyloid-β channel)
  - Optional: CD31 or additional channels  
- Images should be 2D or Z-projected to 2D.

**Output**

- Background-corrected multichannel images:  
  `Adjusted_<filename>.tif`
- Quantification CSV file:  
  `BoundingBoxer_ArterialAbeta_results.csv`  
  containing intensity and integrated density (IntDen) of Aβ within arterial ROIs.

---

## 2. Software Requirements

- Fiji / ImageJ (<https://imagej.net/software/fiji/>)
- CLIJ2 GPU extensions (included with recent Fiji versions)
- No third-party plugins required

---

## 3. Step 1 — Preprocessing

**Macro**

`Fig5_c_d_e_Preprocessing_ArterialAbeta.ijm`

**Purpose**

- Rescale each channel to a defined intensity window
- Convert all channels to 16-bit
- Perform GPU-accelerated background subtraction on the Aβ channel:
  - Difference-of-Gaussian (DoG) feature enhancement  
  - Greyscale opening (background estimation)  
  - Subtraction of background → Aβ enhancement  

> Note: This performs *background correction*, not deconvolution.

**Outputs**

- `Adjusted_<filename>.tif` saved into the chosen output directory
- Original input images optionally moved to a relocation/archive directory

**How to run**

1. In Fiji: `Plugins → Macros → Run...`
2. Select `Fig5_c_d_e_Preprocessing_ArterialAbeta.ijm`
3. Choose:
   - **Input directory** (raw images)
   - **Output directory** (processed `Adjusted_*.tif`)
   - **Relocate directory** (archive, optional)
4. Run the macro.

---

## 4. Step 2 — Arterial ROI Detection & Aβ Measurement

**Macro**

`Fig5_c_d_e_BoundingBoxer_ArterialAbeta.ijm`

**Purpose**

- Detect arterial regions via α-SMA channel (default: Channel 1)
- Filter ROIs based on size (e.g. remove < 200 px²)
- Optionally enlarge arterial ROIs
- Measure Aβ and α-SMA intensity metrics per ROI
- Write results to:  
  `BoundingBoxer_ArterialAbeta_results.csv`

**Measurements include**

- ROI index
- Channel index/name
- Area
- Mean / Min / Max intensity
- Integrated density (IntDen)

**How to run**

1. In Fiji: `Plugins → Macros → Run...`
2. Select `Fig5_c_d_e_BoundingBoxer_ArterialAbeta.ijm`
3. Choose:
   - **Input folder** (`Adjusted_*.tif` from Step 1)
   - **Output folder** (where CSV is saved)
   - **File suffix** (usually `.tif`)
4. Run the macro.

---

## 5. Key Customizable Settings

Both macros include a **SETTINGS** section at the top of the code.

**Examples — Preprocessing macro**

```java
abetaChannel = 3;        // which channel contains Aβ
c1_min = 0; c1_max = 600;
c2_min = 0; c2_max = 700;
c3_min = 0; c3_max = 500;
sigma1x = 1.0; sigma2x = 5.0;
radius_x = 50.0;

Examples — BoundingBoxer macro

alphaChannel = 1;
measureChannels = newArray(1, 3);
minAreaPixels = 200;
expandPixels = 3;
alphaThresholdMethod = "Otsu";

Interpretation of Results

The file BoundingBoxer_ArterialAbeta_results.csv
contains one row per (ROI × channel).

To analyze Aβ signal:

Filter rows by the channel index/name corresponding to Aβ.

Use Integrated Density (IntDen) to compare Aβ load across genotypes or conditions.

Use this release version of:

Fig5_c_d_e_Preprocessing_ArterialAbeta.ijm

Fig5_c_d_e_BoundingBoxer_ArterialAbeta.ijm

Ensure correct channel order (default: C1 = α-SMA, C3 = Aβ).

Calibrate pixel/µm scale in Fiji if required.

Run Preprocessing first → produces Adjusted_*.tif.

Run BoundingBoxer second → generates BoundingBoxer_ArterialAbeta_results.csv.

Document:

Threshold method

ROI area cutoff

Provide the OSF DOI for sample input data in your Methods:
https://doi.org/10.17605/OSF.IO/SYZGA
