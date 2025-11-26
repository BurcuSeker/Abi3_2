Neuronal Activity Analysis – Suite2p + Evoked Response Pipeline
================================================================

This folder contains the complete analysis pipeline used to quantify
**neuronal calcium activity during whisker stimulation**, consisting of:

1. **ROI extraction and ?F/F computation using Suite2p**
2. **Stimulus-evoked response analysis using Python**
   (`Fig7_Neuronal_activity_analysis.py`)

This README provides a clean, step-by-step guide to running the pipeline
from raw two-photon calcium imaging movies to final population- and
group-level calcium response metrics.

----------------------------------------------------------------------
1. Overview of the Workflow
----------------------------------------------------------------------

Input:
- Two-photon calcium imaging movies (e.g., GCaMP-based recordings)

Step 1 — Suite2p (cell detection & ?F/F extraction):
- Motion correction (rigid + non-rigid)
- Automated neuron/ROI detection
- Neuropil subtraction
- Extraction of fluorescence traces per neuron
- ?F/F0 calculation
- Optional spike deconvolution

Output of Suite2p (for this project):
- Excel file `ABI3.xlsx` containing per-cell ?F/F0 traces

Step 2 — Python Script (evoked whisker response analysis):
- Loads ?F/F0 traces from Excel
- Segments traces around stimulation epochs
- Identifies responsive cells
- Computes trial-averaged ?F/F0 responses
- Produces population-level summary plots
- Performs baseline vs peak statistics

----------------------------------------------------------------------
2. Software Requirements
----------------------------------------------------------------------

2.1 Suite2p
- Suite2p (Python package)
- Documentation: https://suite2p.readthedocs.io
- Reference: Pachitariu et al., *bioRxiv*, 2017

Used here for:
- Registration
- ROI detection
- Neuropil subtraction
- ?F/F computation

2.2 Python environment (for Fig7_Neuronal_activity_analysis.py)
Python = 3.8 with:

    numpy
    pandas
    matplotlib
    seaborn
    scipy

Install with:

    pip install numpy pandas matplotlib seaborn scipy

----------------------------------------------------------------------
3. Step 1 — Suite2p Processing
----------------------------------------------------------------------

3.1 Input to Suite2p
Raw two-photon calcium imaging movies, organized according to Suite2p's
recommended folder structure.

3.2 What Suite2p does
Per dataset:
- Registers movies
- Detects ROIs (cells)
- Extracts raw and neuropil-corrected fluorescence
- Computes ?F/F0 per cell

3.3 Exporting data for this project
Export per-cell ?F/F0 traces into Excel:

    ABI3.xlsx

Expected format:
- Column 0: frame index or time (ignored by script)
- Columns 1..N: ?F/F0 traces per cell

Example Suite2p output tables are provided on OSF (below).

----------------------------------------------------------------------
4. Step 2 — Evoked Response Analysis (Python)
----------------------------------------------------------------------

Script:
    Fig7_Neuronal_activity_analysis.py

4.1 Inputs and settings (at top of script):

    file_path = r'...ABI3.xlsx'
    frame_rate = 28  # Hz
    stim_ranges = [(5000, 5500), (8000, 8500), (11000, 11500), (14000, 14500)] (can differ subject to subject)

    pre_stim_sec = 10
    post_stim_sec = 10
    baseline_window_sec = 2
    sd_threshold = 2

Settings to adjust:
- file_path: path to ABI3.xlsx
- frame_rate: imaging framerate
- stim_ranges: (start_frame, end_frame) for each whisker stimulation epoch
- pre/post windows
- baseline length
- SD threshold for responsiveness

4.2 Per-cell analysis
For each cell & each stimulation epoch:
- Extracts time window around stimulus
- Computes baseline (pre-stimulation)
- Computes ?F/F0 for the window
- Determines responsiveness based on SD threshold
- Stores:
  - full ?F/F0 trace
  - baseline
  - peak response

4.3 Population-level averaging
Across all responsive trials & cells:
- Aligns traces to stimulus onset
- Computes mean ?F/F0 and SEM
- Generates:
  - Mean ± SEM time-course plot
  - Baseline vs peak panel
  - Histograms of baseline vs peak

4.4 Statistics
Computes:
- Shapiro–Wilk tests
- Paired t-test (baseline vs peak)
- Cohen’s d
- Wilcoxon signed-rank

Outputs:
- Mean ± SD baseline and peak values
- p-values & significance stars
- Number of responsive cells & trials

----------------------------------------------------------------------
5. Group-Level Comparison Plots
----------------------------------------------------------------------

Using:
    Analysis bulk response.xlsx

The script generates:
- Paired baseline vs stimulation response (one cohort)
- Mean ?F/F0 traces ± SEM for multiple cohorts
- Stimulus timing shading

Used for manuscript neuronal comparisons.

----------------------------------------------------------------------
6. Example Data (OSF)
----------------------------------------------------------------------

Sample Suite2p output tables and example ?F/F0 traces are available at:

OSF DOI:
https://doi.org/10.17605/OSF.IO/SYZGA

----------------------------------------------------------------------
END OF DOCUMENT
----------------------------------------------------------------------