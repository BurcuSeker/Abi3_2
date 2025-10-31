RAW DATA – SUPPLEMENTARY FIGURE 5
PLAQUE FRAGMENTATION ANALYSIS (ALL PLAQUES INCLUDED)

Overview:
This folder contains the raw Imaris exports used for the plaque fragmentation analysis shown in Supplementary Figure 5 of the manuscript.
The analysis quantifies plaque fragmentation based on the volumes (µm³) of all detected plaques in the Methoxy channel.

Image reconstruction:
- Images were reconstructed using Imaris (Version 9.4).
- Channel of interest: CH4 (Methoxy channel).

Data generation steps:
1. In Imaris, select the Methoxy channel (CH4) and create a surface (Surface 4).
2. Export plaque statistics without applying any volume-based filtering.
   - All detected plaques, regardless of size, were included in this analysis.
3. In the “Statistics” tab of Imaris, export all statistics for the surface object to `.csv` files.

Data used for plotting:
- From the exported `.csv` files, the “Volume” parameter of each plaque was extracted.
- These exported data were later processed and plotted using Python to show the overall plaque volume distribution and fragmentation pattern across all plaques.

Plotting:
- The plots were generated in Python using pandas, matplotlib, and seaborn.
- Each data point corresponds to one plaque surface.
- Volumes are expressed in µm³.
- Plots were exported as PDF and PNG files and stored in:
results\plots_coded

Provenance:
- The raw Imaris-exported statistics files in this folder are unchanged.
- The processed data and Python analysis outputs are located in:
  data\data_coded\ and results\figures\scripts\
- The complete dataset will be archived on Zenodo under the project’s dataset DOI.
