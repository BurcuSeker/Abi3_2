# -*- coding: utf-8 -*-
"""
Created on Wed Nov  5 17:56:08 2025

@author: gicaland
"""

# =============================================================================
# ANALYSIS OF NEURONAL EVOKED RESPONSE
# =============================================================================

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

# USER SETTINGS
file_path = r'N:\AGPlesnila\B_Lab members\Schwarz Alexandra\4 ABI3\ABI3 2pH\613 ABI3_KI_+\Data figures Gian Marco\Neuronal activity\ABI3.xlsx'
frame_rate = 28  # Hz
stim_ranges = [(5000, 5500), (8000, 8500), (11000, 11500), (14000, 14500)]

pre_stim_sec = 10
post_stim_sec = 10
baseline_window_sec = 2
sd_threshold = 2

pre_stim_frames = int(pre_stim_sec * frame_rate)
post_stim_frames = int(post_stim_sec * frame_rate)
baseline_frames = int(baseline_window_sec * frame_rate)
stim_duration_frames = stim_ranges[0][1] - stim_ranges[0][0]

print(f"Cell-based analysis ({pre_stim_sec}s pre, {post_stim_sec}s post stimulus)")

df = pd.read_excel(file_path)
print(f"Loaded: {df.shape[0]} rows, {df.shape[1]} columns")

all_responsive_trials = []
all_baseline_values = []
all_peak_values = []
responsive_cells = 0

for col_idx in range(1, len(df.columns)):
    trace = df.iloc[:, col_idx].dropna().to_numpy(dtype=float)
    cell_trials = []
    cell_baseline_values = []
    cell_peak_values = []
    is_responsive = False
    
    for stim_start, stim_end in stim_ranges:
        extended_start = stim_start - pre_stim_frames
        extended_end = stim_end + post_stim_frames
        
        if extended_start < 0 or extended_end >= len(trace):
            continue
            
        baseline_start = stim_start - baseline_frames
        baseline_end = stim_start
        baseline = np.mean(trace[baseline_start:baseline_end])
        baseline_sd = np.std(trace[baseline_start:baseline_end])
        
        extended_trace = trace[extended_start:extended_end]
        delta_f = (extended_trace - baseline) / baseline
        
        stim_period_in_extended = delta_f[pre_stim_frames:pre_stim_frames + (stim_end - stim_start)]
        if np.max(stim_period_in_extended) > sd_threshold * baseline_sd / baseline:
            cell_trials.append(delta_f)
            is_responsive = True
            
            baseline_period = delta_f[:pre_stim_frames]
            stim_period = delta_f[pre_stim_frames:pre_stim_frames + stim_duration_frames]
            
            trial_baseline = np.nanmean(baseline_period)
            trial_peak = np.nanmax(stim_period)
            
            cell_baseline_values.append(trial_baseline)
            cell_peak_values.append(trial_peak)

    if is_responsive and len(cell_trials) > 0:
        responsive_cells += 1
        all_responsive_trials.extend(cell_trials)
        all_baseline_values.extend(cell_baseline_values)
        all_peak_values.extend(cell_peak_values)

print(f"Responsive cells: {responsive_cells}")
print(f"Total trials: {len(all_responsive_trials)}")

if len(all_responsive_trials) > 0:
    all_baseline_values = np.array(all_baseline_values)
    all_peak_values = np.array(all_peak_values)
    
    max_trial_length = max(len(trial) for trial in all_responsive_trials)
    padded_trials = np.array([
        np.pad(trial, (0, max_trial_length - len(trial)), constant_values=np.nan)
        for trial in all_responsive_trials
    ], dtype=float)
    
    overall_mean_trace = np.nanmean(padded_trials, axis=0)
    overall_sem_trace = np.nanstd(padded_trials, axis=0) / np.sqrt(np.sum(~np.isnan(padded_trials), axis=0))
    
    time_ms = (np.arange(max_trial_length) - pre_stim_frames) * (1000 / frame_rate)
    stim_duration_ms = stim_duration_frames * (1000 / frame_rate)
    
    plt.figure(figsize=(10, 6), dpi=300)
    plt.plot(time_ms, overall_mean_trace, color='red', linewidth=3,
            label=f'Mean ΔF/F₀ (n={len(all_responsive_trials)} trials)')
    plt.fill_between(time_ms, 
                    overall_mean_trace - overall_sem_trace, 
                    overall_mean_trace + overall_sem_trace, 
                    color='red', alpha=0.3, label='SEM')
    
    plt.axvspan(0, stim_duration_ms, color='lightblue', alpha=0.3, label='Stimulus')
    plt.axvline(0, color='blue', linestyle='--', alpha=0.7)
    plt.axvline(stim_duration_ms, color='blue', linestyle='--', alpha=0.7)
    
    baseline_start_ms = -baseline_window_sec * 1000
    plt.axvspan(baseline_start_ms, 0, color='gray', alpha=0.2, label='Baseline')
    
    plt.axhline(0, color='black', linestyle='-', alpha=0.3)
    plt.xlabel('Time from stimulus onset (ms)', fontsize=12)
    plt.ylabel('ΔF/F₀', fontsize=12)
    plt.title(f'All Responsive Cells ({responsive_cells} cells, {len(all_responsive_trials)} trials)', 
              fontsize=14, fontweight='bold')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()
    
    plt.figure(figsize=(10, 6), dpi=300)
    
    plt.subplot(1, 2, 1)
    bp = plt.boxplot([all_baseline_values, all_peak_values], positions=[1, 2], widths=0.6,
                     patch_artist=True, boxprops=dict(facecolor='lightblue', alpha=0.7))
    
    n_points = min(50, len(all_baseline_values))
    indices = np.random.choice(len(all_baseline_values), n_points, replace=False)
    
    np.random.seed(42)
    x1 = np.random.normal(1, 0.04, n_points)
    x2 = np.random.normal(2, 0.04, n_points)
    
    plt.scatter(x1, all_baseline_values[indices], c='steelblue', alpha=0.6, s=20, edgecolors='none')
    plt.scatter(x2, all_peak_values[indices], c='coral', alpha=0.6, s=20, edgecolors='none')
    
    for i in range(min(20, n_points)):
        idx = indices[i]
        plt.plot([x1[i], x2[i]], [all_baseline_values[idx], all_peak_values[idx]], 
                'gray', alpha=0.3, linewidth=0.5)
    
    plt.xticks([1, 2], ['Baseline', 'Peak'], fontsize=12)
    plt.ylabel('ΔF/F₀', fontsize=12)
    plt.title(f'Baseline vs Peak (n={len(all_baseline_values)})', fontsize=12, fontweight='bold')
    plt.grid(axis='y', alpha=0.3)
    plt.axhline(y=0, color='black', linestyle='-', alpha=0.3)
    
    plt.subplot(1, 2, 2)
    plt.hist(all_baseline_values, bins=30, alpha=0.7, color='steelblue', 
             label=f'Baseline', density=True)
    plt.hist(all_peak_values, bins=30, alpha=0.7, color='coral', 
             label=f'Peak', density=True)
    plt.axvline(np.mean(all_baseline_values), color='blue', linestyle='--', 
                label=f'Baseline mean: {np.mean(all_baseline_values):.3f}')
    plt.axvline(np.mean(all_peak_values), color='red', linestyle='--', 
                label=f'Peak mean: {np.mean(all_peak_values):.3f}')
    
    plt.xlabel('ΔF/F₀', fontsize=12)
    plt.ylabel('Density', fontsize=12)
    plt.title('Distribution Comparison', fontsize=12, fontweight='bold')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.show()
    
    print("\n" + "="*50)
    print("STATISTICAL ANALYSIS")
    print("="*50)
    
    print(f"Baseline - Mean: {np.mean(all_baseline_values):.4f} ± {np.std(all_baseline_values, ddof=1):.4f}")
    print(f"Peak - Mean: {np.mean(all_peak_values):.4f} ± {np.std(all_peak_values, ddof=1):.4f}")
    
    response_magnitudes = all_peak_values - all_baseline_values
    print(f"Response - Mean: {np.mean(response_magnitudes):.4f} ± {np.std(response_magnitudes, ddof=1):.4f}")
    
    if len(all_baseline_values) > 2:
        shapiro_baseline = stats.shapiro(all_baseline_values[:5000] if len(all_baseline_values) > 5000 else all_baseline_values)
        shapiro_peak = stats.shapiro(all_peak_values[:5000] if len(all_peak_values) > 5000 else all_peak_values)
        
        print(f"\nNormality (Shapiro-Wilk):")
        print(f"  Baseline: W = {shapiro_baseline[0]:.4f}, p = {shapiro_baseline[1]:.6f}")
        print(f"  Peak: W = {shapiro_peak[0]:.4f}, p = {shapiro_peak[1]:.6f}")
    
    if len(all_baseline_values) > 1:
        t_stat, t_p = stats.ttest_rel(all_peak_values, all_baseline_values)
        effect_size = (np.mean(all_peak_values) - np.mean(all_baseline_values)) / np.sqrt(((len(all_peak_values)-1)*np.var(all_peak_values, ddof=1) + (len(all_baseline_values)-1)*np.var(all_baseline_values, ddof=1)) / (2*len(all_peak_values)-2))
        
        print(f"\nPaired t-test:")
        print(f"  t({len(all_baseline_values)-1}) = {t_stat:.4f}, p = {t_p:.2e}")
        print(f"  Cohen's d = {effect_size:.4f}")
        
        if t_p < 0.001:
            print(f"  Result: *** (p < 0.001)")
        elif t_p < 0.01:
            print(f"  Result: ** (p < 0.01)")
        elif t_p < 0.05:
            print(f"  Result: * (p < 0.05)")
        else:
            print(f"  Result: ns (p ≥ 0.05)")
        
        try:
            w_stat, w_p = stats.wilcoxon(all_peak_values, all_baseline_values)
            print(f"\nWilcoxon signed-rank test:")
            print(f"  W = {w_stat:.4f}, p = {w_p:.2e}")
        except:
            print(f"  Wilcoxon test: Could not compute")
    
    print(f"\nSUMMARY:")
    print(f"  {responsive_cells} responsive cells")
    print(f"  {len(all_responsive_trials)} total trials")
    print(f"  Mean response: {np.mean(response_magnitudes):.4f} ΔF/F₀")
    print(f"  Peak response: {np.max(overall_mean_trace):.4f} ΔF/F₀")
    
#%%
# =============================================================================
# COMPARISON PLOTS - BASELINE VS STIMULATION
# =============================================================================

df = pd.read_excel(r'N:\AGPlesnila\B_Lab members\Schwarz Alexandra\4 ABI3\ABI3 2pH\613 ABI3_KI_+\Data figures Gian Marco\Neuronal activity\Analysis bulk response.xlsx','Baseline vs peak Burcu')

ABI3_BL6 = df[df["Group"]=="BL6"]

baseline_vals = ABI3_BL6[ABI3_BL6['Phase'] == 'Baseline']['Values'].values
stimulation_vals = ABI3_BL6[ABI3_BL6['Phase'] == 'Stimulation']['Values'].values

plt.figure(figsize=(3, 3), dpi=300)

for i in range(len(baseline_vals)):
    color = 'red' if stimulation_vals[i] > baseline_vals[i] else 'blue'
    plt.plot([0, 1], [baseline_vals[i], stimulation_vals[i]], 
             color=color, alpha=0.6, linewidth=1)

plt.scatter([0]*len(baseline_vals), baseline_vals, alpha=0.6, s=60)
plt.scatter([1]*len(stimulation_vals), stimulation_vals, alpha=0.6, s=60)

plt.xticks([0, 1], ['Baseline', 'Stimulation'])
plt.ylabel('Values')
plt.ylim(-2, 32)
plt.xlim(-0.3, 1.3)
plt.title('Paired Baseline vs Stimulation')
plt.show()
#%%
# =============================================================================
# COMPARISON PLOTS - ALL COHORTS
# =============================================================================


df_ABI3pp = pd.read_excel(r'N:\AGPlesnila\B_Lab members\Schwarz Alexandra\4 ABI3\ABI3 2pH\613 ABI3_KI_+\Data figures Gian Marco\Neuronal activity\Analysis bulk response.xlsx','ABI3++')
df_ABI3KI = pd.read_excel(r'N:\AGPlesnila\B_Lab members\Schwarz Alexandra\4 ABI3\ABI3 2pH\613 ABI3_KI_+\Data figures Gian Marco\Neuronal activity\Analysis bulk response.xlsx','ABI3KI+')
df_WT = pd.read_excel(r'N:\AGPlesnila\B_Lab members\Schwarz Alexandra\4 ABI3\ABI3 2pH\613 ABI3_KI_+\Data figures Gian Marco\Neuronal activity\Analysis bulk response.xlsx','WT')

plt.figure(figsize=(4, 3), dpi=300)

plt.plot(df_ABI3pp['Time_ms'], df_ABI3pp['Mean_Delta_F_over_F0'], 
         color='#0F99B2', linewidth=2, label='ABI3++')
plt.fill_between(df_ABI3pp['Time_ms'], 
                 df_ABI3pp['Mean_Delta_F_over_F0'] - df_ABI3pp['SEM_Delta_F_over_F0'],
                 df_ABI3pp['Mean_Delta_F_over_F0'] + df_ABI3pp['SEM_Delta_F_over_F0'],
                 color='#0F99B2', alpha=0.3)

plt.plot(df_ABI3KI['Time_ms'], df_ABI3KI['Mean_Delta_F_over_F0'], 
         color='#0000C0', linewidth=2, label='ABI3KI+')
plt.fill_between(df_ABI3KI['Time_ms'], 
                 df_ABI3KI['Mean_Delta_F_over_F0'] - df_ABI3KI['SEM_Delta_F_over_F0'],
                 df_ABI3KI['Mean_Delta_F_over_F0'] + df_ABI3KI['SEM_Delta_F_over_F0'],
                 color='#0000C0', alpha=0.3)

plt.plot(df_WT['Time_ms'], df_WT['Mean_Delta_F_over_F0'], 
         color='#90BFF9', linewidth=2, label='WT')
plt.fill_between(df_WT['Time_ms'], 
                 df_WT['Mean_Delta_F_over_F0'] - df_WT['SEM_Delta_F_over_F0'],
                 df_WT['Mean_Delta_F_over_F0'] + df_WT['SEM_Delta_F_over_F0'],
                 color='#90BFF9', alpha=0.3)

stim_duration_ms = 500
plt.axvspan(0, stim_duration_ms, color='lightblue', alpha=0.3, label='Stimulus')
plt.axvline(0, color='black', linestyle='--', alpha=0.7)

plt.axhline(0, color='black', linestyle='-', alpha=0.3)
plt.xlabel('Time from stimulus onset (ms)')
plt.ylabel('ΔF/F₀')
plt.title('Calcium Response Comparison Between Cohorts')
plt.legend()
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()