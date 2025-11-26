%% 07 - Summarize Results: Generate group-level images, ROI data, and figures

% Clear all except key variables
clearvars -except fnameSubjects dirResults;

%% Parameters
groupNames = {'GroupA', 'GroupB'};
outputImageSize = 120;
nEpochsMax = 5;
colorScaleLimits = [3, 15];
cmap = spring(96);
nContours = 15;
maskBorders = 2;

%% ROI Grid (for analysis & visualization)
gridWidth = 6;
roiCoordinates = [3, 2; 3, 5; 4, 5];
gridMask = create_spherical_mask(gridWidth, gridWidth/2);

%% Visualize grid layout
hf = figure();
imagesc(repmat([1:gridWidth 0:gridWidth-1], 1, ceil(gridWidth/2)));
colormap(gray);
axis equal tight;
title('Grid for ROI analysis (grey panels are masked out)');
fnamePNG = fullfile(dirResults, sprintf('grid%d.png', gridWidth));
export_fig(fnamePNG, '-r144', hf);
close(hf);

%% Load QC-passed dataset
fnameSubjectsQC = regexprep(fnameSubjects, '.xlsx$', '_withQC.xlsx');
DS = readtable(fnameSubjectsQC);
DS(~isnan(DS.exclude), :) = [];

%% Parse metadata
DS.animal = regexprep(DS.fnameDat, '_.*.dat', '');
DS.day = ones(height(DS), 1);
[~, DS.group] = cellfun(@fileparts, DS.folder, 'UniformOutput', false);
x = tabulate(DS.animal);
x = cell2table(x(:,1:2), 'VariableNames', {'animal','nDatasets'});
DS = outerjoin(DS, x, 'MergeKeys', true);
DS = sortrows(DS, {'group', 'day', 'nDatasets'}, {'ascend','ascend','descend'});

%% Load averaged results
for i = 1:height(DS)
    fnameIn = regexprep(fullfile(DS.folder{i}, DS.fnameDat{i}), '\.dat$', sprintf('_results_realigned_k%d.mat', outputImageSize));
    DD(i) = load(fnameIn);
end

%% Filter out excluded stimulation epochs
if isnumeric(DS.excludeStimulation)
    DS.excludeStimulation = cellstr(num2str(DS.excludeStimulation));
    idx = strcmp(DS.excludeStimulation, 'NaN');
    DS.excludeStimulation(idx) = {''};
end

DS.nEpochsFound = zeros(height(DS), 1);
DS.nEpochsExcluded = zeros(height(DS), 1);
for i = 1:height(DS)
    DS.nEpochsFound(i) = size(DD(i).imgStim, 3);
    if ~isempty(DS.excludeStimulation{i})
        idxExc = str2double(regexp(DS.excludeStimulation{i}, ',', 'split'));
        DD(i).imgBl(:, :, idxExc) = [];
        DD(i).imgStim(:, :, idxExc) = [];
        DS.nEpochsExcluded(i) = length(idxExc);
    end
end

%% Limit to max number of epochs
for i = 1:length(DD)
    if size(DD(i).imgStim, 3) > nEpochsMax
        DD(i).imgBl = DD(i).imgBl(:, :, 1:nEpochsMax);
        DD(i).imgStim = DD(i).imgStim(:, :, 1:nEpochsMax);
    end
end

%% Calculate ratio images
for i = 1:length(DD)
    DD(i).imgRatio = DD(i).imgStim ./ DD(i).imgBl;
end

ratio = (cell2mat(reshape(arrayfun(@(d) mean(d.imgRatio, 3), DD, 'UniformOutput', false), 1, 1, [])) - 1) * 100;
ratioGrid = (cell2mat(reshape(arrayfun(@(d) imresize(mean(d.imgRatio, 3), [gridWidth, gridWidth]), DD, 'UniformOutput', false), 1, 1, [])) - 1) * 100;

%% Smooth
sigma = 3;
ratioSmooth = nan(size(ratio));
for i = 1:size(ratio, 3)
    ratioSmooth(:, :, i) = imgaussfilt(ratio(:, :, i), sigma);
end

%% Save for stats
save(fullfile(dirResults, 'ratio.mat'), 'ratio', 'ratioSmooth', 'DS');

%% Plot summary heatmaps (simplified)
[ratioGroupMeanSmoothed] = grand_means(DS, [], ratioSmooth, maskBorders, false);
RGMS = cat(3, ratioGroupMeanSmoothed{:});
RGMS2 = [montage_3D_to_2D(RGMS(:,:,1:end), length(unique(DS.day)))];

hf = plot_grand_means(length(unique(DS.day)), 1, RGMS2, colorScaleLimits, cmap);
fnamePNG = fullfile(dirResults, sprintf('grand_means_smooth_CLim-%g-%g.png', colorScaleLimits));
export_fig(fnamePNG, '-r144', hf);

fprintf('\n✅ Summary completed. Results saved to: %s\n', dirResults);
