%% 03 - Define ROI (Prepare): Load data for manual ROI definition

% Clear all except global parameters
clearvars -except fnameSubjects dirQC;

%% Load subject table
DS = readtable(fnameSubjects);

%% Read and visualize each dataset for manual ROI selection
readOnly = true;
for i = 1:height(DS)
    fprintf('\n\nReading %d. file: %s\n', i, DS.fnameDat{i});
    fullPath = fullfile(DS.folder{i}, DS.fnameDat{i});
    h = visualize_perfusion_raw(fullPath, DS.fps(i), readOnly);
    waitfor(h);  % Wait for user to close figure
end

fprintf('\n✅ ROI preparation complete. Ready for manual editing in the next step.\n');
