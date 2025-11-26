%% 05 - Average Epochs: Process signals and generate summary figures

% Clear all except required variables
clearvars -except fnameSubjects dirQC dirResults;

%% Parameters
outputImageSize = 120;                     % Output image resolution
wndStimDuration = [10, 30];               % Time window within stimulation (sec)

%% Load subject table
DS = readtable(fnameSubjects);

%% Exclude marked datasets
DS(DS.exclude == 1, :) = [];

%% Average across all datasets
for i = 1:height(DS)
    fnameIn = fullfile(DS.folder{i}, DS.fnameDat{i});
    fprintf('\n\nProcessing %d. file: %s\n', i, fnameIn);
    average_stimulation_period_compare(fnameIn, DS.fps(i), wndStimDuration, DS.excludeStimulation(i), outputImageSize);
end

%% Assign random IDs for blinding
DS.rnd = randperm(height(DS))';
fnameSubjectsRndXLSX = regexprep(fnameSubjects, '.xlsx$', '_rnd.xlsx');
writetable(sortrows(DS(:, {'rnd','exclude','excludeStimulation'})), fnameSubjectsRndXLSX);

fnameSubjectsRndMAT = regexprep(fnameSubjects, '.xlsx$', '_rnd.mat');
save(fnameSubjectsRndMAT, 'DS');

%% Open and update result figures (invisible)
for iRnd = 1:height(DS)
    idx = find(DS.rnd == iRnd);
    fnameIn = fullfile(DS.folder{idx}, DS.fnameDat{idx});
    [~, name] = fileparts(fnameIn);
    fnameFig = fullfile(DS.folder{idx}, [name, sprintf('_results_realigned_k%d.fig', outputImageSize)]);
    hf(iRnd) = open(fnameFig);
    hf(iRnd).Visible = false;

    haT = findobj(hf(iRnd), 'Type', 'axes');
    titleStr = sprintf('Random ID: %d', iRnd);
    
    for j = 1:4
        ha = haT(end - j + 1);
        ha.Title.String = titleStr;
        ha.Title.FontSize = 8;
        ha.Title.Interpreter = 'none';
    end
end

%% Merge subplots and export overview figures
hfEpochs = axis_merge(haT(end), 0, 3);
hfEpochs.Position = [300 1 2150 1340];
fnamePNG = fullfile(dirQC, sprintf('overview_signal_in_quadrants_k%d.png', outputImageSize));
export_fig(fnamePNG, '-r144', hfEpochs);

fprintf('\n✅ Averaging complete. Ready to perform QC and unblinding.\n');
