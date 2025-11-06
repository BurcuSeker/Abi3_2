# -*- coding: utf-8 -*-
"""
Suppl Fig 5 — Plaque fragmentation: distribution of ALL plaque volumes

Provenance:
  Input Excel exported/collated for Suppl Fig 5:
  data/Processed/SupplFig5_Plaque_fragmentation.xlsx
"""

import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from scipy.stats import gaussian_kde, ks_2samp
from itertools import combinations
import os

# =======================
# Repo-relative I/O paths
# =======================
file_path = os.path.join("data", "Processed", "SupplFig5_Plaque_fragmentation.xlsx")
plot_dir  = os.path.join("results", "figures", "scripts")
os.makedirs(plot_dir, exist_ok=True)

# ✅ Load the Excel file (keep your sheet selection)
df = pd.read_excel(file_path, sheet_name="Sheet1")

# ✅ Extract unique groups (kept)
groups = df["Group Name"].unique()

# ✅ Define selected groups (kept: second then first)
selected_groups = [groups[1], groups[0]]  # Adjust order if needed

# ✅ Define zoom intervals and bin setup (kept)
zoom_intervals = [(200, 1000), (200, 1000)]
bin_size = 100
bin_edges = np.arange(0, 80000 + bin_size, bin_size)
bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

# ✅ Storage for histogram and KDE data (kept)
global_counts = {}
global_bin_edges = {}
zoomed_kde_data = {}
zoomed_samples = {}

for group in selected_groups:
    group_data = df[df["Group Name"] == group]["Volume"]
    counts, _ = np.histogram(group_data, bins=bin_edges, density=True)
    global_counts[group] = counts
    global_bin_edges[group] = bin_edges
    zoomed_kde_data[group] = []

# ✅ Colors (kept)
hist_colors = ["#0F99B2", "#0000C0"]

# ✅ Plot: Histogram + KDE subplot (kept)
fig, axes = plt.subplots(nrows=1, ncols=2, figsize=(12, 5), sharey=True)

for i, (group, zoom_range) in enumerate(zip(selected_groups, zoom_intervals)):
    counts = global_counts[group]
    bin_edges = global_bin_edges[group]
    zoom_min, zoom_max = zoom_range
    zoom_mask = (bin_edges[:-1] >= zoom_min) & (bin_edges[1:] <= zoom_max)
    valid_indices = np.where(zoom_mask)[0]

    if len(valid_indices) > 0:
        bar_centers = bin_centers[valid_indices]
        bar_widths = np.diff(bin_edges)[valid_indices]

        axes[i].bar(bar_centers, counts[valid_indices],
                    width=bar_widths, align='center', alpha=0.5,
                    color=hist_colors[i % len(hist_colors)], edgecolor="black",
                    label=group)

        zoomed_data = df[(df["Group Name"] == group) &
                         (df["Volume"] >= zoom_min) &
                         (df["Volume"] <= zoom_max)]["Volume"]
        zoomed_samples[group] = zoomed_data.to_numpy()

        if len(zoomed_data) > 1:
            kde = gaussian_kde(zoomed_data, bw_method=0.2)
            kde_x = np.linspace(zoom_min, zoom_max, 100)
            kde_y = kde(kde_x)

            # normalize KDE area to match histogram area in the zoom window (kept)
            kde_area = np.trapz(kde_y, kde_x)
            hist_area = np.sum(counts[valid_indices] * bar_widths)
            kde_y *= hist_area / kde_area

            axes[i].plot(kde_x, kde_y,
                         color=hist_colors[i % len(hist_colors)], linewidth=2,
                         label=f"{group} KDE")

    # ✅ Axis labels/titles/fonts (kept)
    axes[i].set_xlabel("Volume (µm³)", fontsize=20, fontweight='regular')
    axes[i].set_ylabel("Probability Density (µm⁻³)", fontsize=20)
    axes[i].set_title(f"Density of {group}", fontsize=20, fontweight='bold')
    axes[i].tick_params(axis='both', which='major', labelsize=16)
    axes[i].legend(loc="upper right", fontsize=14)

# ✅ Save histogram + KDE plot (repo path)
out_hist = os.path.join(plot_dir, "SupplFig5_volume_density_histograms.svg")
plt.tight_layout()
plt.savefig(out_hist, format='svg', dpi=300)
plt.show()
print(f"[OK] Saved: {out_hist}")

# ✅ Statistical Test (kept: KS on zoomed samples)
print("\nKolmogorov–Smirnov test on zoomed data:")
for g1, g2 in combinations(selected_groups, 2):
    x1 = zoomed_samples.get(g1, np.array([]))
    x2 = zoomed_samples.get(g2, np.array([]))
    if len(x1) > 1 and len(x2) > 1:
        res = ks_2samp(x1, x2)
        print(f"{g1} vs {g2}: D = {res.statistic:.4f}, p = {res.pvalue:.4g} (n1={len(x1)}, n2={len(x2)})")
    else:
        print(f"{g1} vs {g2}: Not enough data in the zoom range.")

# ✅ Plot: KDE-only overlay (kept)
plt.figure(figsize=(8, 5))
for i, group in enumerate(selected_groups):
    if len(zoomed_kde_data[group]) > 0:
        zoom_x, zoom_y = zoomed_kde_data[group]
        plt.plot(zoom_x, zoom_y,
                 color=hist_colors[i % len(hist_colors)], linewidth=2,
                 label=f"{group} KDE")

plt.xlabel("Volume (µm³)", fontsize=20)
plt.ylabel("Kernel Density Estimate (µm⁻³)", fontsize=20)
plt.title("Zoomed-in KDE Curves for Selected Groups", fontsize=18, fontweight='bold')
plt.tick_params(axis='both', which='major', labelsize=16)
plt.legend(loc="upper right", fontsize=14)
plt.tight_layout()

# ✅ Save KDE-only plot (repo path)
out_kde = os.path.join(plot_dir, "SupplFig5_volume_kde_overlay.svg")
plt.savefig(out_kde, format='svg', dpi=300)
plt.show()
print(f"[OK] Saved: {out_kde}")
print(f"[OK] Input file: {file_path}")
