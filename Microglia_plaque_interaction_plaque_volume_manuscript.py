# -*- coding: utf-8 -*-
"""
Created on Fri Feb 21 15:10:02 2025
Complete Analysis Script: Volume Analysis and Group-Wise Correlation With Outlier Removal
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import scipy.stats as stats
import numpy as np

# ✅ Define Custom RGB Colors for Groups
group_1_color = (15/255, 153/255, 178/255)  # Cyan-like for scatter points
group_2_color = (0/255, 0/255, 192/255)  # Deep Blue for scatter points
line_color_1 = "darkcyan"  # Regression line color for Group 1
line_color_2 = "darkblue"  # Regression line color for Group 2

# ✅ Load Data
file_path = r'Microglia_associated_with_Plaques_plaques_Int_Sum_above1000um3.xlsx'
data = pd.read_excel(file_path)

# ✅ Clean Column Names
data.columns = data.columns.str.strip()
data['Group'] = data['Group'].str.strip()

# ✅ Separate Groups
group_1_name = "Abi3$^{+/+}$; APP/PS1"
group_2_name = "Abi3$^{KI/+}$; APP/PS1"

group_1_data = data[data['Group'] == "APP/PS1_12m old"]
group_2_data = data[data['Group'] == "Abi3(het)_APP/PS1_12m old"]

# ✅ Function to Remove Outliers Using IQR
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

# ✅ Perform Correlation Analysis
def correlation_analysis(group_data):
    corr_test = stats.spearmanr(group_data['Volume'].dropna(), group_data['Intensity_Sum'].dropna())
    return corr_test.correlation, corr_test.pvalue, len(group_data)

corr_1, pval_1, n1 = correlation_analysis(group_1_data_clean)
corr_2, pval_2, n2 = correlation_analysis(group_2_data_clean)

print(f"{group_1_name}: Spearman ρ = {corr_1:.4f}, p = {pval_1:.2e}, n = {n1}")
print(f"{group_2_name}: Spearman ρ = {corr_2:.4f}, p = {pval_2:.2e}, n = {n2}")

# ✅ Fisher's r-to-z transformation
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

# ✅ Plotting
plt.figure(figsize=(12, 8))

# Group 1 Scatter Plot
sns.regplot(
    x='Volume', y='Intensity_Sum', data=group_1_data_clean,
    scatter_kws={'color': group_1_color, 'alpha': 0.5},
    line_kws={'color': line_color_1, 'linewidth': 2},
    #label=f"{group_1_name} (ρ={corr_1:.2f})"
)

# Group 2 Scatter Plot
sns.regplot(
    x='Volume', y='Intensity_Sum', data=group_2_data_clean,
    scatter_kws={'color': group_2_color, 'alpha': 0.5},
    line_kws={'color': line_color_2, 'linewidth': 2},
    #label=f"{group_2_name} (ρ={corr_2:.2f})"
)

# ✅ Plot Formatting
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

# ✅ Annotate ρ and R² on plot
r2_1 = corr_1 ** 2
r2_2 = corr_2 ** 2

plt.text(1000, 3.8e9, f"{group_1_name}\nρ = {corr_1:.2f}, R² ≈ {r2_1:.2f}", fontsize=14, color=line_color_1)
plt.text(1000, 3.2e9, f"{group_2_name}\nρ = {corr_2:.2f}, R² ≈ {r2_2:.2f}", fontsize=14, color=line_color_2)


plt.tight_layout()
plt.show()

