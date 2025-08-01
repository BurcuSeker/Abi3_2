# -*- coding: utf-8 -*-
"""
Created on Thu Mar 20 13:21:04 2025

@author: bseker
"""

# ✅ Import Libraries
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os
import numpy as np
from scipy.stats import ks_2samp, mannwhitneyu

# ✅ Reset Seaborn Settings for Clear Visualizations
sns.reset_defaults()
sns.set_style("whitegrid")  # Use whitegrid for better visibility

# ✅ Define font settings for publication quality
font_settings = {
    "font.family": "Arial",
    "axes.titleweight": "regular",
    "axes.labelweight": "regular",
    "axes.labelsize": 26,
    "axes.titlesize": 26,
    "xtick.labelsize": 20,
    "ytick.labelsize": 26,
    "legend.fontsize": 20,
    "legend.title_fontsize": 20
}
plt.rcParams.update(font_settings)

# ✅ Ensure File Path and Load Data (if not already loaded)
file_path = r"C:\Users\bseker\Desktop\Spyder_coding\Plaque_diffusivity_combined_data.csv"
if 'df' not in globals():
    df = pd.read_csv(file_path)

# ✅ Plot Saving Directory
plot_dir = r"C:\Users\bseker\Desktop\Spyder_coding\Plots"
os.makedirs(plot_dir, exist_ok=True)

# ✅ Define Custom RGB Colors for Groups
group_1_color = (15/255, 153/255, 178/255)  # Group 1 Color (Cyan-like)
group_2_color = (0/255, 0/255, 192/255)    # Group 2 Color (Deep Blue)

# ✅ Extract Group Names from Data
group_1_name = r"Abi3$^{+/+}$; APPPS1"  # Adjusted format for publication
group_2_name = r"Abi3$^{KI/+}$; APPPS1"  # Adjusted format for publication

# ✅ Data Subsets
group_1_data = df[df["Subject Name"] == "APP/PS1_12m old"]["Intensity Max"]
group_2_data = df[df["Subject Name"] == "Abi3(het)_APP/PS1_12m old"]["Intensity Max"]

# ✅ Print Information
print("Unique Groups in 'Subject Name':", df["Subject Name"].unique())
print(f"Number of data points in {group_1_name}: {len(group_1_data)}")
print(f"Number of data points in {group_2_name}: {len(group_2_data)}")

# ✅ Statistical Tests
ks_stat, ks_pvalue = ks_2samp(group_1_data, group_2_data)
u_stat, u_pvalue = mannwhitneyu(group_1_data, group_2_data, alternative="two-sided")

print(f"Kolmogorov-Smirnov Test: Statistic = {ks_stat:.4f}, p-value = {ks_pvalue:.4e}")
print(f"Mann-Whitney U Test: U = {u_stat:.4f}, p-value = {u_pvalue:.4e}")

# ✅ Simplify P-value Display
def format_p_value(p):
    if p < 0.0001:
        return "< 0.0001"
    else:
        return f"{p:.4f}"

# ✅ Combined Boxplot and Strip Plot
plt.figure(figsize=(8, 5))

# ✅ Boxplot
ax = sns.boxplot(x="Subject Name", y="Intensity Max", data=df, 
                 palette=[group_1_color, group_2_color], width=0.6)

# ✅ Strip Plot on Top of Boxplot
sns.stripplot(x="Subject Name", y="Intensity Max", data=df, 
              color="black", size=4, alpha=0.6, jitter=True)

# ✅ Adjust x-axis labels with group names
ax.set_xticklabels([group_1_name, group_2_name])

# ✅ Remove x-axis label
plt.xlabel("")

# ✅ Statistical Annotation
p_text = f"p = {format_p_value(u_pvalue)}"
plt.text(0.5, max(df["Intensity Max"]) * 1.00, p_text, ha="center", fontsize=14, color="black")

# ✅ Labels and Title
plt.ylabel("Plaque Intensity\n(Intensity Max)")

# ✅ Customize Plot Frame (Spines) - Make Axis Lines Black
ax.spines['top'].set_visible(False)    # Hide the top spine
ax.spines['right'].set_visible(False)  # Hide the right spine
ax.spines['left'].set_color("black")   # Set left spine color to black
ax.spines['bottom'].set_color("black") # Set bottom spine color to black
ax.spines['left'].set_linewidth(1.5)   # Adjust the left spine thickness
ax.spines['bottom'].set_linewidth(1.5) # Adjust the bottom spine thickness

# ✅ Remove Grid Lines
ax.grid(False)

# ✅ Set Background Color (Optional: White for Clean Look)
ax.set_facecolor("white")




# ✅ Adjust legend position
plt.legend(loc="upper right", frameon=False)

# ✅ Save the Plot
plt.tight_layout()
plt.savefig(os.path.join(plot_dir, "intensity_max_boxplot_strip_with_stats.svg"), format="svg", dpi=300)
plt.show()

# ✅ Final Confirmation
print(f"All plots have been successfully saved in: {plot_dir}")
