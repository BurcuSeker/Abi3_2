%% 04 - Define ROI (Manually): Manual editing and QC of spatial/temporal ROIs

% Clear all except necessary paths and filenames
clearvars -except fnameSubjects dirQC;

%% Load subject table and start ROI editing
[DS, idx] = manage_ROI_editing(fnameSubjects);

while idx <= height(DS)
    folderTemp = regexprep(DS.folder{idx}, {'\\\\.*?\\','\\'}, {'/Volumes/','/'});
    fullPath = fullfile(folderTemp, DS.fnameDat{idx});
    h = visualize_perfusion_raw(fullPath, DS.fps(idx), false);
    waitfor(h);
    [DS, idx] = manage_ROI_editing(fnameSubjects, DS, idx);
end

%% Save editing progress
[folder, fname] = fileparts(fnameSubjects);
fnameCheckEditing = fullfile(folder, [fname, '.mat']);
save(fnameCheckEditing, 'DS');

%% Generate overview of signal timecourses
clc;
close all;
DS = readtable(fnameSubjects);
DS.folder = regexprep(DS.folder, {'\\\\.*?\\','\\'}, {'/Volumes/','/'});

nS = height(DS);
for i = 1:nS
    fnameIn = fullfile(DS.folder{i}, DS.fnameDat{i});
    fnameIn = regexprep(fnameIn, '\.dat$', '_ROI.mat');
    fprintf('\n\nReading %d. file: %s\n', i, fnameIn);
    DD(i) = load(fnameIn);
end

roiSignal = reshape([DD.roiSignal], 4, [])';
dur = roiSignal(:,3) ./ DS.fps;
durMax = max(dur);

hf = figure;
hf.Position = [637 3 1233 1342];
for i = 1:nS
    ax(i) = subplot(nS, 1, i);
    analize_detect_perfusion(ax(i), DD(i).I2, DD(i).roiSignal, DS.fps(i));
    xx = [0, durMax * DS.fps(i)];
    xlim(xx); ylim([-30 50]);
    ht = title(sprintf('%d:  %s', i, DS.fnameDat{i}), 'Interpreter','none', 'FontSize', 10);
    ht.HorizontalAlignment = 'left';
    ht.Position(1:2) = [0, 50];
    if i < nS
        ax(i).XTick = [];
    else
        temp = 0:120:durMax;
        ax(i).XTick = temp * DS.fps(i);
        ax(i).XTickLabel = temp / 60;
        xlabel('minutes');
    end
end

% Merge axes and export figure
hf3 = axis_merge(hf, 0, 3);
hf3.Position = [300 1 2150 1340];
fnamePNG = fullfile(dirQC, 'overview_average_signal.png');
export_fig(fnamePNG, '-r144', hf3);

fprintf('\n✅ Manual ROI definition complete.\n');
