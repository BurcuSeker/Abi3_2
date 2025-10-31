RAW DATA – SUPPLEMENTARY FIGURE 5
PLAQUE FRAGMENTATION ANALYSIS (VOLUME DISTRIBUTION OF PLAQUES)

Overview:
This folder contains the raw Imaris exports used for the plaque fragmentation analysis shown in Supplementary Figure 5 of the manuscript.
The analysis quantifies plaque fragmentation based on individual plaque volumes (µm³) and compares plaque populations by size range.

Image reconstruction:
- Images were reconstructed using Imaris (Version 9.4).
- Channel of interest: CH4 (Methoxy channel).

Data generation steps:
1. In Imaris, select the Methoxy channel (CH4) and create a surface (Surface 4, surface detail: 0.345).
2. In the “Funnel” section of the Surfaces tool, set up a filter to select plaques based on volume:
   - Select “Volume” as the filtering variable.
   - Enter 1000 (µm³) as the threshold.
   - All plaques with a volume of 1000 µm³ and above will be selected.
3. Click “Duplicate Surface” at the bottom of the Filtering tab to create a new surface containing only plaques = 1000 µm³.
4. To isolate smaller plaques, change the filter to select plaques between 200 µm³ and 1000 µm³:
   - Set the range to 200–1000 µm³.
   - Duplicate the filtered surface again to create a new surface for intermediate-sized plaques.
5. For each surface (200–1000 µm³ and =1000 µm³):
   - Open the “Statistics” tab in Imaris.
   - Export all statistics to .csv files.

Data used for plotting:
- From each exported .csv file, the “Volume” parameter of every plaque surface was extracted.
- These exported data were processed and plotted later using Python.
- The Python script compared plaque populations:
   • Group 1: plaques with volume 200–1000 µm³  
   • Group 2: plaques with volume =1000 µm³
- The resulting plots show plaque volume distribution and fragmentation differences between these two size groups.

Plotting:
- The plots were generated in Python (Version 3.x) using pandas, matplotlib, and seaborn.
- Each data point corresponds to a single plaque surface.
- Volumes are expressed in µm³.
- Plots were exported as PDF and PNG files and stored in:
  results\figures\scripts\

Provenance:
- The raw Imaris-exported statistics files in this folder are unchanged.
- The processed data and Python analysis outputs are located in:
  data\data_coded\ and results\figures\scripts\
- The complete dataset will be archived on Zenodo under the project’s dataset DOI.
