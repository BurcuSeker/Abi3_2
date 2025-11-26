# -*- coding: utf-8 -*-
"""
Created on Wed Dec  4 19:09:26 2024

@author: JShroude
"""
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 14 11:05:22 2024

@author: JShroude
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib.patches import Rectangle
from scipy.signal import butter, filtfilt, savgol_filter
import tkinter as tk
from tkinter import filedialog, simpledialog, messagebox
from tkinter import ttk  # Import for advanced Tkinter widgets
import subprocess
import tempfile
import os
import shutil
import matplotlib.image as mpimg
import numpy as np

# Force Matplotlib to use a non-inline backend
plt.switch_backend('Qt5Agg')  # Use 'Qt5Agg' for a new window

# Function to load the CSV file
def load_csv():
    file_path = filedialog.askopenfilename(title="Select CSV file", filetypes=[("CSV files", "*.csv")])
    df = pd.read_csv(file_path)
    print("Data loaded successfully.")
    print(df.head())
    return df

# Function to remove legends
def remove_legends(axes):
    for ax in axes:
        legend = ax.get_legend()
        if legend is not None:
            legend.remove()


# Function to save the plot
def save_plot(fig, title):
    save_path = filedialog.asksaveasfilename(title="Save Plot As", initialfile=title, defaultextension=".png", filetypes=[("PNG files", "*.png")])
    fig.savefig(save_path)

# Function to normalize the data
def normalize_data(df, baseline_range):
    baseline_mean = df.loc[baseline_range[0]-1:baseline_range[1]-1, 'Rolling Median (microns)'].mean()
    df['Normalized Mean (%)'] = (df['Rolling Median (microns)'] / baseline_mean) * 100
    return df

# Function to save the normalized dataframe to Excel
def save_to_excel(df, title):
    save_path = filedialog.asksaveasfilename(title="Save Excel File As", initialfile=title, defaultextension=".xlsx", filetypes=[("Excel files", "*.xlsx")])
    df.to_excel(save_path, index=False)

# Function to add analysis parameters to the dataframe and plot

# Function to apply a Butterworth filter
def apply_butterworth_filter(data, cutoff, fs, order=4):
    nyquist = 0.5 * fs
    normal_cutoff = cutoff / nyquist
    b, a = butter(order, normal_cutoff, btype='low', analog=False)
    y = filtfilt(b, a, data)
    return y

# Function to apply a Savitzky-Golay filter
def apply_savgol_filter(data, window_length, polyorder):
    return savgol_filter(data, window_length, polyorder)
def calculate_average_time_to_dilation(df, baseline_end_frame, max_dilation_frame):
    """
    Calculate the time it takes for the vessel to reach 10% of the maximum dilation.
    - Start from the baseline end frame.
    - Calculate the maximum dilation relative to the baseline.
    - Find the frame where the signal exceeds 10% of the maximum dilation.
    """
    signal_column = 'Filtered Mean (%)' if 'Filtered Mean (%)' in df.columns else 'Normalized Mean (%)'

    # Maximum signal value and frame
    max_dilation_value = df.loc[max_dilation_frame, signal_column]
    baseline_value = 100.0  # Normalized baseline is 100%

    # Calculate maximum dilation (above baseline) and the 10% threshold
    max_dilation = max_dilation_value - baseline_value
    threshold = baseline_value + (0.1 * max_dilation)

    # Filter relevant frames (baseline end to max dilation frame)
    relevant_df = df[(df['Frame'] >= baseline_end_frame) & (df['Frame'] <= max_dilation_frame)]

    # Find the first frame where the signal exceeds the threshold
    for _, row in relevant_df.iterrows():
        if row[signal_column] >= threshold:
            time_to_dilation = row['Time (seconds)'] - df.loc[baseline_end_frame, 'Time (seconds)']
            return time_to_dilation

    # If the threshold is never reached, return None
    return None


# Updated add_analysis_params function
def add_analysis_params(df, baseline_end_frame, stim_end_frame, ax, label_prefix, frame_interval):
    """
    Adds analysis parameters to the dataframe and plots them.
    - Calculates Median Diameter Change, Max Diameter Change, Time to Peak, 
      and Average Time to Dilation for the stimulation.
    """
    signal_column = 'Filtered Mean (%)' if 'Filtered Mean (%)' in df.columns else 'Normalized Mean (%)'

    post_baseline_df = df[(df['Frame'] > baseline_end_frame) & (df['Frame'] <= stim_end_frame)]
    median_diameter_change = post_baseline_df[signal_column].median()
    max_dilation_value = post_baseline_df[signal_column].max()
    max_dilation_frame = post_baseline_df[signal_column].idxmax()
    time_to_peak = df.loc[max_dilation_frame, 'Time (seconds)'] - df.loc[baseline_end_frame, 'Time (seconds)']

    # Calculate Average Time to Dilation (10% of max dilation)
    average_time_to_dilation = calculate_average_time_to_dilation(df, baseline_end_frame, max_dilation_frame)

    # Plot metrics on the given axis
    if ax is not None:
        ax.axvline(df.loc[max_dilation_frame, 'Time (seconds)'], color='gold', linestyle='--', alpha=0.5)
        rect_max = Rectangle(
            (df.loc[max_dilation_frame, 'Time (seconds)'], df[signal_column].min()), 
            frame_interval, 
            df[signal_column].max() - df[signal_column].min(),
            linewidth=1, edgecolor='none', facecolor='gold', alpha=0.3
        )
        ax.add_patch(rect_max)

        textstr = '\n'.join((f'{label_prefix} Median Diameter Change: {median_diameter_change:.2f}%',
                             f'{label_prefix} Max Diameter Change: {max_dilation_value - 100:.2f}%',
                             f'{label_prefix} Time to Peak: {time_to_peak:.2f} sec',
                             f'{label_prefix} Avg Time to Dilation (10% max): {average_time_to_dilation:.2f} sec' if average_time_to_dilation is not None else f'{label_prefix} Avg Time to Dilation: N/A'))
        props = dict(boxstyle='round', facecolor='wheat', alpha=0.5)
        ax.text(1.05, 0.95, textstr, transform=ax.transAxes, fontsize=10,
                verticalalignment='top', bbox=props)

    # Add computed metrics to the dataframe
    df['Median Diameter Change (%)'] = median_diameter_change
    df['Max Diameter Change (%)'] = max_dilation_value - 100  # Subtract baseline
    df['Time to Peak (sec)'] = time_to_peak
    df['Average Time to Dilation (sec)'] = average_time_to_dilation

    return df



def call_jython_script(frames_dict, directory, stimulation_number):
    with tempfile.TemporaryDirectory() as tmpdirname:
        jython_script_path = os.path.join(tmpdirname, "script.py")
        jython_script = f"""
from ij import IJ, ImagePlus
from ij.gui import WaitForUserDialog
from ij.plugin.frame import RoiManager
from loci.plugins import BF
from loci.plugins.in import ImporterOptions
from ij.io import FileSaver
import os

# Function to wait until the image is fully loaded and displayed
def wait_for_image():
    for _ in range(20):  # Try for 10 seconds max
        imp = IJ.getImage()
        if imp is not None and imp.isVisible():
            IJ.log("Image successfully loaded.")
            return imp
        IJ.log("Waiting for image to load...")
    IJ.error("Image did not load correctly.")
    exit()

# Prompt the user to open a CZI file
options = ImporterOptions()
options.setVirtual(True)  # Use virtual stack
file_path = IJ.getFilePath("Select CZI file")
if file_path is None:
    IJ.error("No file selected. Please select a CZI file.")
    exit()
options.setId(file_path)
options.setOpenAllSeries(True)
imps = BF.openImagePlus(options)
imp = imps[0]
imp.show()

# Wait for the image to be fully loaded
imp = wait_for_image()

# Wait for user to confirm ROI selection
IJ.run("Select None")
IJ.log("Please select an ROI and press OK in the ImageJ dialog.")
IJ.run("ROI Manager...", "")
WaitForUserDialog("ROI Selection", "Please select an ROI and press OK.").show()

# Ensure the ROI Manager is ready and set the ROI
roi_manager = RoiManager.getInstance()
if roi_manager is None:
    roi_manager = RoiManager()

roi = imp.getRoi()
if roi is None or roi.getFloatWidth() <= 0 or roi.getFloatHeight() <= 0:
    IJ.error("Invalid or no ROI selected. Please select a valid rectangular ROI.")
    exit()

# Add the ROI to the ROI Manager
roi_manager.addRoi(roi)
roi_manager.rename(roi_manager.getCount() - 1, "Selected_ROI")

# Define the frames dictionaries
frames_dict = {frames_dict}

# Create directories for saving the duplicated images
directory = r"{directory}"
stimulation_dir = os.path.join(directory, 'Stimulation{stimulation_number}')  # Create unique stimulation directory

# Check if the directory exists, and if not, create it
if not os.path.exists(stimulation_dir):
    os.makedirs(stimulation_dir)

# Function to duplicate and save the ROI at specified frames
def save_roi_images(frames_dict, save_dir, imp, roi_manager):
    for label, frame in frames_dict.items():
        imp.setT(frame)
        IJ.log("Selected frame: " + str(frame) + " for " + label)
        roi_manager.select(0)
        imp.setRoi(roi_manager.getRoi(0))
        cropped = imp.crop()
        width = imp.getWidth()
        height = imp.getHeight()
        cropped_width = cropped.getWidth()
        cropped_height = cropped.getHeight()
        IJ.log("Frame: " + label + ", Frame number: " + str(frame) + ", Original image dimensions: " + str(width) + " x " + str(height))
        IJ.log("Frame: " + label + ", Cropped image dimensions: " + str(cropped_width) + " x " + str(cropped_height))
        if cropped_width <= 0 or cropped_height <= 0:
            IJ.log("Invalid cropped image dimensions for " + label + ". Skipping this frame.")
            continue
        cropped.setTitle(label + "_Frame_" + str(frame))
        fs = FileSaver(cropped)
        fs.saveAsTiff(os.path.join(save_dir, label + "_Frame_" + str(frame) + ".tif"))

# Save images for the current stimulation
save_roi_images(frames_dict, stimulation_dir, imp, roi_manager)

IJ.log("Images saved successfully!")

# Close the ROI Manager explicitly
if roi_manager is not None:
    roi_manager.close()

# Ensure that everything is closed
IJ.run("Close All")

# Wait for user to confirm before exiting
WaitForUserDialog("Completion", "Images have been saved successfully and the ROI Manager has been closed. Click OK to proceed.").show()

IJ.log("Script completed.")

# Exit ImageJ to ensure everything is properly closed
IJ.exit()

# Exit with a successful return code
exit(0)
"""
        with open(jython_script_path, "w") as script_file:
            script_file.write(jython_script)

        # Update the path to the Jython executable
        jython_path = r"C:/jython2.7.3/bin/jython.exe"  # Update this to the correct path to Jython
        ij_jar_path = r"D:/Transfer/Fiji.app/jars/ij-1.54f.jar"  # Update this to the correct path to ij-1.54f.jar
        bioformats_jar_path = r"D:/Transfer/Fiji.app/jars/bioformats_package.jar"  # Update this to the correct path to bioformats_package.jar
        classpath = f"{ij_jar_path};{bioformats_jar_path}"
        env = os.environ.copy()
        env["CLASSPATH"] = classpath

        print(f"Running Jython script from {jython_script_path}...")
        try:
            # Start the process
            proc = subprocess.Popen(
                [jython_path, jython_script_path],
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            # Stream output
            for line in proc.stdout:
                print(line, end="")

            proc.wait(timeout=600)  # Wait for the process to finish

            # If the process is still running, terminate it
            if proc.poll() is None:
                print("Jython script still running, terminating it.")
                proc.terminate()
                proc.wait()  # Ensure the process has finished

            if proc.returncode != 0:
                print(f"Jython script error: {proc.stderr.read()}")
            else:
                print("Jython script completed successfully.")

        except subprocess.TimeoutExpired:
            print("The Jython script took too long to complete and was terminated.")
            proc.kill()

        return proc.returncode == 0

    
# Function to display a dynamic GUI for parameter input based on the number of baselines
import tkinter as tk
from tkinter import ttk

# Function to display a dynamic GUI for parameter input based on the number of baselines
def display_parameter_gui():
    root = tk.Tk()
    root.title("Enter Parameters")

    # Create a canvas to hold the widgets and add a scrollbar
    canvas = tk.Canvas(root)
    scrollbar = tk.Scrollbar(root, orient="vertical", command=canvas.yview)
    scrollable_frame = ttk.Frame(canvas)

    scrollable_frame.bind(
        "<Configure>",
        lambda e: canvas.configure(
            scrollregion=canvas.bbox("all")
        )
    )

    canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
    canvas.configure(yscrollcommand=scrollbar.set)

    canvas.pack(side="left", fill="both", expand=True)
    scrollbar.pack(side="right", fill="y")

    params = {}

    # Frame Interval
    ttk.Label(scrollable_frame, text="Frame Interval (seconds):").grid(row=0, column=0)
    frame_interval_entry = ttk.Entry(scrollable_frame)
    frame_interval_entry.grid(row=0, column=1)

    # Window Size for Rolling Median
    ttk.Label(scrollable_frame, text="Window Size for Rolling Median:").grid(row=1, column=0)
    window_size_entry = ttk.Entry(scrollable_frame)
    window_size_entry.grid(row=1, column=1)

    # Number of Baselines
    ttk.Label(scrollable_frame, text="Number of Baselines:").grid(row=2, column=0)
    num_baselines_entry = ttk.Entry(scrollable_frame)
    num_baselines_entry.grid(row=2, column=1)

    baseline_entries = []
    stim_end_entries = []

    def update_baseline_entries():
        # Clear any existing baseline/stimulation entries
        for entry in baseline_entries + stim_end_entries:
            entry.destroy()
        baseline_entries.clear()
        stim_end_entries.clear()

        # Get the number of baselines
        num_baselines = int(num_baselines_entry.get())

        for i in range(num_baselines):
            # Baseline Frame Range
            ttk.Label(scrollable_frame, text=f"Baseline {i+1} Frame Range (e.g., 1-100):").grid(row=3 + i*2, column=0)
            baseline_entry = ttk.Entry(scrollable_frame)
            baseline_entry.grid(row=3 + i*2, column=1)
            baseline_entries.append(baseline_entry)

            # Stimulation End Frame
            ttk.Label(scrollable_frame, text=f"Stimulation {i+1} End Frame:").grid(row=4 + i*2, column=0)
            stim_end_entry = ttk.Entry(scrollable_frame)
            stim_end_entry.grid(row=4 + i*2, column=1)
            stim_end_entries.append(stim_end_entry)

        # Update the position of the submit button
        submit_button.grid(row=3 + num_baselines*2, column=0, columnspan=2)

    # Button to update the baseline entries when the number of baselines is entered
    update_button = ttk.Button(scrollable_frame, text="Update", command=update_baseline_entries)
    update_button.grid(row=2, column=2)

    # Filter Selection
    ttk.Label(scrollable_frame, text="Apply Filter (butterworth/savgol/none):").grid(row=5, column=0)
    filter_entry = ttk.Entry(scrollable_frame)
    filter_entry.grid(row=5, column=1)

    # Function to collect inputs
    def collect_inputs():
        params['frame_interval'] = float(frame_interval_entry.get())
        params['window_size'] = int(window_size_entry.get())
        params['num_baselines'] = int(num_baselines_entry.get())
        params['baseline_ranges'] = [list(map(int, entry.get().split('-'))) for entry in baseline_entries]
        params['stim_end_frames'] = [int(entry.get()) for entry in stim_end_entries]
        params['filter_type'] = filter_entry.get().lower()

        root.quit()
        root.destroy()

    # Submit button
    submit_button = ttk.Button(scrollable_frame, text="Submit", command=collect_inputs)
    submit_button.grid(row=6, column=0, columnspan=2)

    root.mainloop()

    return params


    
def place_images_next_to_graph(fig, ax, image_paths, titles, base_position, offset_multiplier=1):
    """
    Function to place images next to the graph, taking care to avoid overlapping important graph elements.

    Parameters:
    - fig: The figure object.
    - ax: The axes object associated with the graph.
    - image_paths: List of image file paths to be placed.
    - titles: List of titles corresponding to each image.
    - base_position: [x, y, width, height] position for the first image. Other images will be placed horizontally relative to this.
    - offset_multiplier: Used to space images vertically based on the graph's index to avoid overlap.
    """
    # Adjust the x_offset and y_offset to increase spacing
    x_offset = base_position[2] + 0.01  # Increased horizontal space between images
    y_offset = base_position[1] - offset_multiplier * 0.05  # Vertical spacing, use `offset_multiplier` to avoid overlap between graphs

    # Dynamically position the images to avoid overlaps
    for i, (img_path, title) in enumerate(zip(image_paths, titles)):
        position = [base_position[0] + i * x_offset, base_position[1], base_position[2], base_position[3]]
        img = mpimg.imread(img_path)
        img_ax = fig.add_axes(position)  # Add axes for the image
        img_ax.imshow(img, cmap='gray')  # Display image in grayscale
        img_ax.axis('off')
        img_ax.set_title(title, fontsize=8)  # Reduce title font size to prevent overlap
        fig.canvas.draw()





# Modify the main function to adjust image placement dynamically for each section
def process_images_for_stimulation(frames_dict, directory, fig, ax, titles, base_position, section_number, offset_multiplier=0):
    """
    Process and place images related to a stimulation.
    Dynamically handles folder creation and places images correctly next to the corresponding graph.
    
    Parameters:
    - frames_dict: The dictionary containing frame numbers.
    - directory: The base directory where images are stored.
    - fig: The figure object.
    - ax: The axes object where the graph is plotted.
    - titles: Titles for the images.
    - base_position: The position for the first image.
    - section_number: The number of the baseline/stimulation section.
    - offset_multiplier: Offset used to prevent overlap in image placement.
    """
    # Create the directory for the current stimulation
    stimulation_dir = os.path.join(directory, f'Stimulation{section_number}')
    if not os.path.exists(stimulation_dir):
        os.makedirs(stimulation_dir)

    # Generate paths for the expected images
    image_paths = [
        os.path.join(stimulation_dir, f'Baseline_Mean_Frame_Frame_{frames_dict["baseline_mean_frame"]}.tif'),
        os.path.join(stimulation_dir, f'Post_Baseline_Mean_Frame_Frame_{frames_dict["post_baseline_mean_frame"]}.tif'),
        os.path.join(stimulation_dir, f'Max_Dilation_Frame_Frame_{frames_dict["max_dilation_frame"]}.tif')
    ]

    # Place images next to the graph with dynamically adjusted offsets
    place_images_next_to_graph(fig, ax, image_paths, titles, base_position, offset_multiplier)

# Main function
def main():
    root = tk.Tk()
    root.withdraw()
    
    df = load_csv()
    
    # Display the GUI to collect parameters
    params = display_parameter_gui()

    frame_interval = params['frame_interval']
    window_size = params['window_size']
    num_baselines = params['num_baselines']
    baseline_ranges = params['baseline_ranges']
    stim_end_frames = params['stim_end_frames']
    filter_type = params['filter_type']

    # Convert Frame to Time
    df['Time (seconds)'] = df['Frame'] * frame_interval
    
    # Apply rolling median to the dataset
    df['Rolling Median (microns)'] = df['Mean (microns)'].rolling(window=window_size, center=True).median()

    # Normalization
    df_sections = []
    for i in range(num_baselines):
        df_section = df.loc[baseline_ranges[i][0]-1:stim_end_frames[i]].copy()
        df_section = normalize_data(df_section, baseline_ranges[i])
        df_section['Baseline Time'] = ''
        df_section.loc[baseline_ranges[i][0]-1:baseline_ranges[i][1]-1, 'Baseline Time'] = 'baseline'
        df_sections.append(df_section)

    # Adjust figure size to account for extra 15% space on the right
    original_fig_width, original_fig_height = 15, 5 * (num_baselines + 1)  # Original figure size
    adjusted_fig_width = original_fig_width * 1.15  # Adding 15% extra width

    # Add 15% extra space to the figure width to accommodate the images on the right
    fig, axes = plt.subplots(num_baselines + 1, 1, figsize=(adjusted_fig_width, original_fig_height))

    # Updated loop in main
    for i in range(num_baselines):
        df_sections[i] = add_analysis_params(
        df_sections[i],  # DataFrame for the current section
        baseline_ranges[i][1],  # End of the baseline range
        stim_end_frames[i],  # End frame of stimulation
        axes[i+1],  # Axis for plotting
        f'Section {i+1}',  # Label prefix
        frame_interval  # Frame interval
    )


    # Save normalized dataframes to Excel
    # Save normalized dataframes to Excel
    for i in range(num_baselines):
        save_to_excel(
        df_sections[i][['Time (seconds)', 'Normalized Mean (%)', 'Baseline Time',
                        'Median Diameter Change (%)', 'Max Diameter Change (%)', 
                        'Time to Peak (sec)', 'Average Time to Dilation (sec)']],
        f'Normalized_Data_Baseline_{i+1}'
    )

    # Apply selected filter
    if filter_type == 'butterworth':
        cutoff_frequency = float(simpledialog.askstring("Input", "Enter the cutoff frequency for the Butterworth filter:"))
        fs = 1 / frame_interval  # Sampling frequency
        for i in range(num_baselines):
            df_sections[i]['Filtered Mean (%)'] = apply_butterworth_filter(df_sections[i]['Normalized Mean (%)'], cutoff_frequency, fs)
    elif filter_type == 'savgol':
        window_length = int(simpledialog.askstring("Input", "Enter the window length for the Savitzky-Golay filter (must be odd):"))
        polyorder = int(simpledialog.askstring("Input", "Enter the polynomial order for the Savitzky-Golay filter:"))
        for i in range(num_baselines):
            df_sections[i]['Filtered Mean (%)'] = apply_savgol_filter(df_sections[i]['Normalized Mean (%)'], window_length, polyorder)
    else:
        for i in range(num_baselines):
            df_sections[i]['Filtered Mean (%)'] = df_sections[i]['Normalized Mean (%)']

    # Plot raw data with highlighted baseline segments
    sns.lineplot(x='Time (seconds)', y='Mean (microns)', data=df, ax=axes[0], label='Mean Diameter')
    axes[0].fill_between(df['Time (seconds)'], df['Mean (microns)'] - df['SD'], df['Mean (microns)'] + df['SD'], alpha=0.3)

    for baseline_range in baseline_ranges:
        start_time = df.loc[baseline_range[0]-1, 'Time (seconds)']
        end_time = df.loc[baseline_range[1]-1, 'Time (seconds)']
        rect = Rectangle((start_time, df['Mean (microns)'].min()), end_time - start_time, df['Mean (microns)'].max() - df['Mean (microns)'].min(),
                         linewidth=1, edgecolor='none', facecolor='gray', alpha=0.3, label='Baseline')
        axes[0].add_patch(rect)

    # Highlight the segments used for the normalized dataframes with reduced opacity green boxes
    for i in range(num_baselines):
        start_time = df.loc[baseline_ranges[i][0]-1, 'Time (seconds)']
        end_time = df.loc[stim_end_frames[i], 'Time (seconds)']
        rect = Rectangle((start_time, df['Mean (microns)'].min()), end_time - start_time, df['Mean (microns)'].max() - df['Mean (microns)'].min(),
                          linewidth=1, edgecolor='none', facecolor='green', alpha=0.1, label=f'Stimulation {i+1}')
        axes[0].add_patch(rect)

    axes[0].set_xlabel('Time (seconds)')
    axes[0].set_ylabel('Mean Diameter (microns)')
    axes[0].set_title('Mean Vessel Diameter Over Time with Baseline and Stimulation Segments')
    
    # Remove unnecessary legends from plots
    remove_legends(axes)

    # Plot each normalized dataframe with highlighted baseline segments
    for i in range(num_baselines):
        sns.lineplot(x='Time (seconds)', y='Filtered Mean (%)', data=df_sections[i], ax=axes[i+1], label=f'Normalized Mean Diameter (Filtered) - Section {i+1}')
        axes[i+1].fill_between(df_sections[i]['Time (seconds)'], df_sections[i]['Filtered Mean (%)'] - df_sections[i]['SD'], df_sections[i]['Filtered Mean (%)'] + df_sections[i]['SD'], alpha=0.3)

        start_time_norm = df_sections[i].loc[baseline_ranges[i][0]-1, 'Time (seconds)']
        end_time_norm = df_sections[i].loc[baseline_ranges[i][1]-1, 'Time (seconds)']
        rect_normalized = Rectangle(
            (start_time_norm, df_sections[i]['Filtered Mean (%)'].min()), 
            end_time_norm - start_time_norm, 
            df_sections[i]['Filtered Mean (%)'].max() - df_sections[i]['Filtered Mean (%)'].min(),
            linewidth=1, edgecolor='none', facecolor='gray', alpha=0.3, label='Baseline'
        )
        axes[i+1].add_patch(rect_normalized)

        # Add horizontal lines for baseline and median post-baseline
        baseline_mean = df_sections[i].loc[baseline_ranges[i][0]-1:baseline_ranges[i][1]-1, 'Filtered Mean (%)'].mean()
        post_baseline_mean = df_sections[i].loc[baseline_ranges[i][1]:stim_end_frames[i], 'Filtered Mean (%)'].mean()
        axes[i+1].axhline(baseline_mean, color='gray', linestyle='--', alpha=0.7, label='Baseline')
        axes[i+1].axhline(post_baseline_mean, color='blue', linestyle='--', alpha=0.7, label='Post-Baseline Mean')

        axes[i+1].set_xlabel('Time (seconds)')
        axes[i+1].set_ylabel('Normalized Mean Diameter (%)')
        axes[i+1].set_title(f'Normalized Vessel Diameter Over Time (Stimulation {i+1})')

    # Add this line to make Matplotlib interactive
    plt.ion()

    # Complete the plot
    fig.tight_layout()
    plt.show()

    # Save the combined plot
    save_plot(fig, 'Normalized_Vessel_Diameter_Combined')

    # Optional: Call Jython script for ImageJ
    frames_dicts = []
    for i in range(num_baselines):
        try:
            baseline_mean_frame = int(df_sections[i].loc[baseline_ranges[i][0] - 1, 'Frame'])
            post_baseline_mean_frame = int(df_sections[i].loc[baseline_ranges[i][1]:stim_end_frames[i], 'Frame'].median())
            max_dilation_frame = int(df_sections[i].loc[df_sections[i]['Normalized Mean (%)'].idxmax(), 'Frame'])

            frames_dict = {
            'baseline_mean_frame': baseline_mean_frame +1,
            'post_baseline_mean_frame': post_baseline_mean_frame +1,
            'max_dilation_frame': max_dilation_frame +1
        }
            print(f"Stimulation {i + 1}: Frames - {frames_dict}")  # Debugging log
            frames_dicts.append(frames_dict)

        except KeyError as e:
            print(f"Error processing stimulation {i + 1}: {e}")
        continue


    # After plotting and saving
    plt.show()  # Display the plot here, so the plot window opens
    directory = filedialog.askdirectory(title="Choose a directory to save duplicated images")

    if directory:
        # Iterate over the number of baselines to handle image processing and Jython script calling for each section
        for i in range(num_baselines):
            # Ensure directories for image saving are created
            stimulation_dir = os.path.join(directory, f'Stimulation{i+1}')
            if not os.path.exists(stimulation_dir):
                os.makedirs(stimulation_dir)

            # Call the Jython script for each baseline and stimulation set
            success = call_jython_script(frames_dicts[i], directory, i + 1)
            if success:
                # Ensure the user is aware that manual placement is next
                messagebox.showinfo("Manual Placement", f"The images for Stimulation {i+1} were successfully generated. Now, they will be placed on the graph.")

                # Paths to the images for each stimulation
                image_paths = [
                    os.path.join(stimulation_dir, f'Baseline_Mean_Frame_Frame_{frames_dicts[i]["baseline_mean_frame"]}.tif'),
                    os.path.join(stimulation_dir, f'Post_Baseline_Mean_Frame_Frame_{frames_dicts[i]["post_baseline_mean_frame"]}.tif'),
                    os.path.join(stimulation_dir, f'Max_Dilation_Frame_Frame_{frames_dicts[i]["max_dilation_frame"]}.tif')
                ]

                titles = [f"Baseline S{i+1}", f"Stimulation Mean S{i+1}", f"Stimulation Max S{i+1}"]

                # Adjust base position dynamically for image placement
                base_position = [0.79, 0.85 - (0.25 * (i + 1)), 0.08, 0.08]  # Shift images further right to accommodate extra space

                # Place images next to the graphs
                process_images_for_stimulation(frames_dicts[i], directory, fig, axes[i+1], titles, base_position, section_number=i + 1)
            else:
                messagebox.showerror("Error", f"The image generation for Stimulation {i+1} failed. Please check the logs for details.")

        # Keep the plot open for manual placement
        plt.show(block=True)

    # After displaying, save the plot and optionally allow the user to export the results
    save_plot(fig, 'Final_Vessel_Diameter_Analysis')

    # Inform the user that the process has completed successfully
    messagebox.showinfo("Process Completed", "Analysis and image generation completed successfully!")

if __name__ == "__main__":
    main()


