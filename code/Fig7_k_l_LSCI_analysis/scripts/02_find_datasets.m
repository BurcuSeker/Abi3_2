%% 02 - Find Datasets: Locate and index all .dat files in the data directory

% Clear existing variables but keep global parameters like fps, fnameSubjects, etc.
clearvars -except fps fnameSubjects dirData;

%% Find all .dat files in subfolders of dirData
fnameIn = glob(fullfile(dirData, '**', '*.dat'));

%% Create a table with info for each file
parts = regexp(fnameIn, filesep, 'split');
DS.folder = cellfun(@fileparts, fnameIn, 'UniformOutput', false);
DS.group = cellfun(@(x) x{end-1}, parts, 'UniformOutput', false);
DS.fnameDat = cellfun(@(x) x{end}, parts, 'UniformOutput', false);
DS = struct2table(DS);
DS.dateAdded(:) = datetime;
DS.fps(:) = fps;

%% Initialize exclusion columns
DS.exclude(:) = nan;
DS.excludeStimulation(:) = nan;

%% Write to Excel (after checking for existing file)
if exist(fnameSubjects, 'file')
    DSx = readtable(fnameSubjects);
    alreadyIncluded = ismember(DS.fnameDat, DSx.fnameDat);

    if all(alreadyIncluded)
        error('No new .dat files found.');
    elseif any(alreadyIncluded)
        warning('%d of the found .dat files were already included previously.', sum(alreadyIncluded));
        DS = outerjoin(DSx, DS(~alreadyIncluded,:), 'MergeKeys', true);
        DS = sortrows(DS, 'dateAdded');
    end
end

% Save the subject table
writetable(DS, fnameSubjects);
fprintf('✅ Found %d new .dat files. Subject table saved to: %s\n', height(DS), fnameSubjects);
