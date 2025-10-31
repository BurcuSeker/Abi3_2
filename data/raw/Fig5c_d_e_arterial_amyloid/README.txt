RAW DATA – ARTERY–AMYLOID BETA COLOCALIZATION ANALYSIS
(INCLUDING aSMA, CD31, AND METHOXY CHANNELS)

Overview:
This folder contains the raw and processed data used for the artery–amyloid beta colocalization analysis shown in the manuscript.
The analysis was performed on confocal image stacks containing arteries and amyloid plaques, to quantify colocalization between smooth muscle (aSMA), endothelial marker (CD31), and amyloid (Methoxy) signals.

Image acquisition and preprocessing:
- Confocal images were acquired from brain sections labeled for:
  • aSMA – arterial smooth muscle
  • CD31 – endothelial cells
  • Methoxy – amyloid deposits
- Image stacks were deconvolved prior to analysis using the ImageJ macro:
  "Deconvolver.ijm"
  (provided in the codes/scripts folder).
- The deconvolution step enhanced image clarity and spatial accuracy.

Colocalization analysis:
- Following deconvolution, colocalization was quantified using the ImageJ macro:
  "Boundingboxer.ijm"
  (provided in the codes/scripts folder).
- This macro:
  • Detects 3D structures in each channel
  • Creates bounding boxes around aSMA
  • Calculates spatial overlap (colocalization) between channels
  • Outputs per-object metrics and overlap summaries

Analyzed channels:
- Channel 1: aSMA (arterial smooth muscle)
- Channel 2: CD31 (endothelium)
- Channel 3: Methoxy (amyloid deposits)

Exported data:
- The macro-generated outputs were exported as CSV files.
- Example file:
- Each CSV contains quantitative colocalization parameters, including:
  • Overlap area (µm²)
  • Percent colocalization between aSMA–Methoxy and CD31–Methoxy
  • Bounding box coordinates (x, y, z)
  • Object intensity and area metrics for each channel

Data interpretation:
- Each row represents one structure or ROI identified in the bounding box analysis.
- Column headers correspond to metrics computed by the macro.
- Data were later aggregated and summarized for plotting and statistical analysis.

Plotting and downstream processing:
- The exported CSV files were combined and analyzed in Python and plotted using GraphPad Prism.
- Derived plots show the extent of colocalization between vascular structures (aSMA, CD31) and amyloid plaques (Methoxy).
- Processed results and summary tables are stored in:
  data\data_coded\ and data\data_graphpad\

Provenance:
- Raw confocal images ? deconvolved (Deconvolver macro) ? analyzed (Boundingboxer macro) ? exported to CSV.
- Both macros are included in the codes/scripts folder fo
