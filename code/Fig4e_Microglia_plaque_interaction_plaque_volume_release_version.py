# -*- coding: utf-8 -*-
"""
Fig 4E — Microglia-associated plaques: Methoxy Intensity Sum vs Plaque Volume
Provenance:
  Input Excel derived from Imaris exports and collated for Fig4E:
  data/Processed/Fig4_e_Microglia_associated_with_Plaques_plaques_Int_Sum_above1000um3.xlsx
"""

# ✅ Import Libraries
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import scipy.stats as stats
import numpy as np
import os

# ✅ Define Custom RGB Colors for Groups
group_1_color = (15/255, 153/255, 178/255)  # Cyan-like for scatter points
group_2_color = (0/255, 0/255, 192/255)     # Deep Blue for scatter points
line_color_1 = "darkcyan"   # Regression line color for Group 1
line_color_2 = "darkblue"   # Regression line color for Group 2

# ✅ Repo-relative paths (ONLY change from your original)
file_path = os.path.join("data", "Processed",
    "Fig4_e_Microglia_associated_with_Plaques_plaques_Int_Sum_above1000um3.xlsx")
plot_dir = os.path.join("results", "figures", "scripts")
os.makedirs(plot_dir, exist_ok=True)

# ✅ Load Data
data = pd.read_excel(file_path)

# ✅ Clean Column Names
data.columns = data.columns.str.strip()
if 'Group' in data.columns:
    data['Group'] = data['Group'].astype(str).str.strip()

# ✅ Separate Groups (keep your original group mapping)
group_1_name = "Abi3$^{+/+}$; APP/PS1"
group_2_name = "Abi3$^{KI/+}$; APP/PS1"

group_1_data = data[data['Group'] == "Abi3+/+_APPPS1"]
group_2_data = data[data['Group'] == "Abi3KI/+_APPPS1"]

# ✅ Function to Remove Outliers Using IQR (unchanged)
def remove_outliers_iqr(df, columns):
    for col in columns:
        Q1 = df[col].quantile(0.25)
        Q3 = df[col].quantile(0.75)
        IQR = Q3 - Q1
        df = df[~((df[col] < (Q1 - 1.5 * IQR)) | (df[col] > (Q3 + 1.5 * IQR)))]
    return df

# ✅ Remove Outliers from Both Groups
group_1_data_clean = remove_outliers_iqr(group_1_data, ['Volume', 'Intensity_Sum'])
group_2_data_clean = remove_outliers_iqr(group_2_data, ['Volume', 'Intensity_Sum'])

# ✅ Perform Correlation Analysis (unchanged)
def correlation_analysis(group_data):
    corr_test = stats.spearmanr(group_data['Volume'].dropna(), group_data['Intensity_Sum'].dropna())
    return corr_test.correlation, corr_test.pvalue, len(group_data)

corr_1, pval_1, n1 = correlation_analysis(group_1_data_clean)
corr_2, pval_2, n2 = correlation_analysis(group_2_data_clean)

print(f"{group_1_name}: Spearman ρ = {corr_1:.4f}, p = {pval_1:.2e}, n = {n1}")
print(f"{group_2_name}: Spearman ρ = {corr_2:.4f}, p = {pval_2:.2e}, n = {n2}")

# ✅ Fisher's r-to-z transformation (unchanged)
def fisher_r_to_z(r):
    return 0.5 * np.log((1 + r) / (1 - r))

def compare_correlations(r1, n1, r2, n2):
    z1 = fisher_r_to_z(r1)
    z2 = fisher_r_to_z(r2)
    se = np.sqrt(1/(n1 - 3) + 1/(n2 - 3))
    z_diff = (z1 - z2) / se
    p_value = 2 * (1 - stats.norm.cdf(abs(z_diff)))
    return z_diff, p_value

# ✅ Compare Correlations
z_diff, p_value = compare_correlations(corr_1, n1, corr_2, n2)
print(f"Difference in correlation (z) = {z_diff:.4f}, p = {p_value:.4e}")

# ✅ Plotting (structure preserved)
plt.figure(figsize=(12, 8))

# Group 1 Scatter + Regression
sns.regplot(
    x='Volume', y='Intensity_Sum', data=group_1_data_clean,
    scatter_kws={'color': group_1_color, 'alpha': 0.5},
    line_kws={'color': line_color_1, 'linewidth': 2},
    #label=f"{group_1_name} (ρ={corr_1:.2f})"
)

# Group 2 Scatter + Regression
sns.regplot(
    x='Volume', y='Intensity_Sum', data=group_2_data_clean,
    scatter_kws={'color': group_2_color, 'alpha': 0.5},
    line_kws={'color': line_color_2, 'linewidth': 2},
    #label=f"{group_2_name} (ρ={corr_2:.2f})"
)

# ✅ Plot Formatting (unchanged)
plt.xlabel('Plaque Volume', fontsize=20, fontweight='regular', fontfamily='Arial')
plt.ylabel('Microglial Intensity Sum', fontsize=20, fontweight='regular', fontfamily='Arial')
plt.xticks(fontsize=20, fontweight='regular', fontfamily='Arial', color='black')
plt.yticks(fontsize=20, fontweight='regular', fontfamily='Arial', color='black')
plt.gca().set_facecolor("white")
ax = plt.gca()
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.spines['left'].set_linewidth(1.5)
ax.spines['bottom'].set_linewidth(1.5)
plt.grid(False)
plt.legend(fontsize=14, frameon=False)

# ✅ Annotate ρ and R² on plot (positions kept)
r2_1 = corr_1 ** 2
r2_2 = corr_2 ** 2
plt.text(1000, 3.8e9, f"{group_1_name}\nρ = {corr_1:.2f}, R² ≈ {r2_1:.2f}",
         fontsize=14, color=line_color_1)
plt.text(1000, 3.2e9, f"{group_2_name}\nρ = {corr_2:.2f}, R² ≈ {r2_2:.2f}",
         fontsize=14, color=line_color_2)

plt.tight_layout()

# ✅ Save (added for release; does not change plot appearance)
out_base = os.path.join(plot_dir, "Fig4E_volume_vs_intensitysum_by_group")
plt.savefig(out_base + ".svg", format="svg", dpi=300)
plt.savefig(out_base + ".png", format="png", dpi=300)

plt.show()
print(f"[OK] Saved: {out_base}.svg/.png")
print(f"[OK] Input file: {file_path}")
