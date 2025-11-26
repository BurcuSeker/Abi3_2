%% 01 - Setup Project: Define paths and parameters for LSCI Data Analysis

% Clear workspace and command window
clearvars;
clc;

%% Add script and function paths
% Automatically add all subfolders of the current repo (assumes user starts here)
addpath(genpath(pwd));

%% Define key directories relative to the project root
baseDir = pwd;  % Base directory of the repo
dirData = fullfile(baseDir, 'data');          % Directory containing raw data
dirResults = fullfile(baseDir, 'results');    % Output results directory
dirQC = fullfile(dirResults, 'QC');           % QC subdirectory
fnameSubjects = fullfile(baseDir, 'data', 'subjects.xlsx');  % Subject metadata file

%% Project-specific parameters
fps = 4.4;  % Frames per second for LSCI acquisition

%% Create required folders if they don't exist
if ~isfolder(dirResults), mkdir(dirResults); end
if ~isfolder(dirQC), mkdir(dirQC); end

%% Next steps:
% After this setup, proceed with the following scripts in order:
% 1. 02_find_datasets.m
% 2. 03_define_ROI_prepare.m
% 3. 04_define_ROI_manually.m
% 4. 05_average_epochs.m
% 5. 06_unblind_QC.m
% 6. 07_summarize_results.m

disp("✅ Project setup complete. Ready to run the next script.");
