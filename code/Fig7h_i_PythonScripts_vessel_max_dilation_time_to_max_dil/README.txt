README — Whisker Stimulation Vessel Analysis Script
File: 051224_WorkingWhiskerStimScriptWithPictures_WithAverageTimetoDilation_timeto10-.py
Author: J. Shroude
Date: December 4, 2024

Overview
--------
This Python script automates the analysis and visualization of vessel diameter changes during whisker stimulation experiments. 
It processes time-series data exported as .csv files (e.g., vessel diameter over time), applies filtering and normalization, 
and calculates several hemodynamic parameters. It also integrates with ImageJ (Fiji) via Jython to extract and display images 
corresponding to key timepoints (baseline, post-stimulation, and max dilation).

Features
--------
- Interactive GUI for parameter input (Tkinter-based):
  * Frame interval (seconds per frame)
  * Rolling median window size
  * Number of baselines/stimulation epochs
  * Baseline frame ranges and stimulation end frames
  * Optional filtering (Butterworth / Savitzky-Golay / none)

- Signal Processing & Analysis:
  * Rolling median smoothing
  * Optional low-pass filtering (Butterworth or Savitzky–Golay)
  * Normalization to baseline (% change)
  * Calculates:
      - Median diameter change (%)
      - Maximum diameter change (%)
      - Time to peak (sec)
      - Average time to dilation (time to reach 10% of max dilation)

- Visualization:
  * Raw data with highlighted baseline/stimulation windows
  * Normalized traces for each stimulation epoch
  * Calculated metrics displayed next to each subplot
  * Optionally includes corresponding microscopy images next to plots

- ImageJ Integration:
  * Uses Jython to call ImageJ/Fiji for interactive ROI selection
  * Automatically duplicates and saves frames (Baseline, Post-baseline, Max Dilation)
  * Saves cropped .tif images in subdirectories for each stimulation epoch

- Output:
  * .xlsx files with processed data and computed metrics
  * .png plots for visual summaries
  * .tif ROI images exported via ImageJ

Dependencies
------------
Python packages required:
    pandas
    matplotlib
    seaborn
    scipy
    numpy
    openpyxl

Additional software:
    - ImageJ/Fiji (with ij-1.54f.jar and bioformats_package.jar)
    - Jython 2.7.3 (ensure path is correctly set inside the script)
    - Windows system recommended for GUI and Jython subprocess calls

Usage
-----
1. Run the script:
       python 051224_WorkingWhiskerStimScriptWithPictures_WithAverageTimetoDilation_timeto10-.py

2. Load the CSV data when prompted.
   Expected columns:
       Frame
       Mean (microns)
       SD

3. Enter analysis parameters in the GUI:
   - Frame interval (e.g., 0.2)
   - Rolling window size (e.g., 5)
   - Number of baselines (e.g., 3)
   - Baseline frame ranges (e.g., 1-100)
   - Stimulation end frames (e.g., 300)
   - Filter type (butterworth / savgol / none)

4. (Optional) Enter filter parameters if selected.

5. The script generates:
   - Plots of vessel diameter and normalized changes
   - Excel files with analyzed data
   - Optional ImageJ/Jython interaction for frame extraction

ImageJ & Jython Integration
---------------------------
- When prompted, select a .czi file in ImageJ.
- Draw and confirm an ROI.
- The script will automatically crop and save ROI images for key frames:
     * Baseline Mean Frame
     * Post-Baseline Mean Frame
     * Max Dilation Frame

Images will be saved in subdirectories:
     <chosen_directory>/Stimulation1/
     <chosen_directory>/Stimulation2/
     ...

Output Files
------------
Excel:
    Normalized_Data_Baseline_#.xlsx

Plots:
    Normalized_Vessel_Diameter_Combined.png
    Final_Vessel_Diameter_Analysis.png

Images:
    Baseline_Mean_Frame_#.tif
    Post_Baseline_Mean_Frame_#.tif
    Max_Dilation_Frame_#.tif

Notes
-----
- Designed for multi-baseline whisker stimulation experiments.
- Assumes baseline normalization reflects steady-state pre-stimulation activity.
- Image placement coordinates (base_position) can be adjusted manually in the script.
- Can be adapted to other vascular or calcium imaging paradigms.

