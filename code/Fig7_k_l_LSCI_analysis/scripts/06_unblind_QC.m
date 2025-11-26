%% 06 - Unblind QC: Merge blinded QC data with original dataset

% Clear all except essential variables
clearvars -except fnameSubjects;

%% Load original dataset
DS = readtable(fnameSubjects);

%% Load randomized subject table (.mat)
fnameSubjectsRndMAT = regexprep(fnameSubjects, '.xlsx$', '_rnd.mat');
RND = load(fnameSubjectsRndMAT, 'DS');
RND = RND.DS(:, {'folder', 'fnameDat', 'rnd'});

%% Join original data with random IDs
DS = outerjoin(DS, RND, 'MergeKeys', true);

%% Load blinded QC results (.xlsx)
fnameSubjectsRndXLSX = regexprep(fnameSubjects, '.xlsx$', '_rnd.xlsx');
QC = readtable(fnameSubjectsRndXLSX);

%% Merge QC results into original table using random IDs
newVars = setdiff(QC.Properties.VariableNames, {'rnd'});
DS = join(DS, QC, 'Keys', 'rnd', 'RightVariables', newVars);

%% Save unblinded dataset
fnameSubjectsQC = regexprep(fnameSubjects, '.xlsx$', '_withQC.xlsx');
if exist(fnameSubjectsQC, 'file')
    delete(fnameSubjectsQC);
end
writetable(DS, fnameSubjectsQC);

fprintf('\n✅ Unblinded subject table saved: %s\n', fnameSubjectsQC);
