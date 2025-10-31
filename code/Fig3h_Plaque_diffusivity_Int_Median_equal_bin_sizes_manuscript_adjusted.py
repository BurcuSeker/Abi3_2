# ✅ Import Libraries
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os
import numpy as np
from scipy.stats import ks_2samp, mannwhitneyu

# ✅ Reset Seaborn Settings for Clear Visualizations
sns.reset_defaults()
sns.set_style("white")  # Removes background grid lines

# ✅ Define font settings for publication quality
font_settings = {
    "font.family": "Calibri",
    "axes.titleweight": "bold",
    "axes.labelweight": "regular",
    "axes.labelsize": 30,
    "axes.titlesize": 30,
    "xtick.labelsize": 16,
    "ytick.labelsize": 1,
    "legend.fontsize": 16,
    "legend.title_fontsize": 16
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
group_1_data = df[df["Subject Name"] == "APP/PS1_12m old"]["Intensity Median"]
group_2_data = df[df["Subject Name"] == "Abi3(het)_APP/PS1_12m old"]["Intensity Median"]

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

# ✅ Histogram by Group with Statistical Results
plt.figure(figsize=(8, 5))

# Plot histograms with density estimation
for group, color, label in zip(df["Subject Name"].unique(), [group_1_color, group_2_color], [group_1_name, group_2_name]):
    sns.histplot(df[df["Subject Name"] == group]["Intensity Median"], 
                 bins=30, kde=True, label=label, alpha=0.6, stat="density", color=color)

# ✅ Labels and Title
plt.xlabel("Plaque Intensity (Median)")
plt.ylabel("Probability Density")
plt.gca().set_facecolor("white")  # Ensure background is white
plt.grid(False)  # Remove grid lines

# ✅ Customize frame to keep only bottom and left
ax = plt.gca()
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.spines['left'].set_color("black")
ax.spines['bottom'].set_color("black")
ax.spines['left'].set_linewidth(1.2)
ax.spines['bottom'].set_linewidth(1.2)


# ✅ Set tick label font styles
plt.xticks(fontsize=26, fontfamily='Calibri', color='black')
plt.yticks(fontsize=26, fontfamily='Calibri', color='black')

# ✅ Customize Legend Font
legend_font = {'family': 'Calibri', 'size': 24}


# ✅ Create Combined Legend with Group Names on Top and Statistical Results Below
handles = [
    plt.Line2D([0], [0], marker='o', color=group_1_color, label=f"{group_1_name}", markersize=8, linestyle='None'),
    plt.Line2D([0], [0], marker='o', color=group_2_color, label=f"{group_2_name}", markersize=8, linestyle='None')
]

legend_text = (
    "---------------------------------------\n"
    f"Kolmogorov-Smirnov Test: D = {ks_stat:.4f}, p = {format_p_value(ks_pvalue)}\n"
    f"Mann-Whitney U Test: U = {u_stat:.4f}, p = {format_p_value(u_pvalue)}"
)

# # ✅ Plot Legend with Group Names on Top and Statistical Results Below
legend = plt.legend(
    handles=handles, loc="upper right", frameon=False, 
    prop=legend_font, handletextpad=0.5, borderpad=0.8, labelspacing=0.5, fontsize=12
)

# ✅ Add the Statistical Results as a Separate Text Block Below the Group Names
# plt.gca().add_artist(legend)
# plt.text(
#     0.97, 0.85, legend_text, transform=plt.gca().transAxes, ha='right', va='top',
#     fontsize=10, family='Calibri', style='normal', bbox=dict(boxstyle="square,pad=0.4", edgecolor="none", facecolor="white", alpha=0.6)
# )



# ✅ Save the Plot
plt.tight_layout()
plt.savefig(os.path.join(plot_dir, "intensity_median_histogram_with_stats_clean.svg"), format="svg", dpi=300)
plt.show()

# ✅ Final Confirmation
print(f"All plots have been successfully saved in: {plot_dir}")
