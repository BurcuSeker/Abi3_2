function [DS, idx] = manage_ROI_editing(fnameSubjects, DS, idx)


%%
[folder, fname] = fileparts(fnameSubjects);
fnameCheckEditing = fullfile(folder, [fname, '.mat']);

%%
if exist('idx','var')
    
    %--- ask whether to mark current subject as edited
    answer = questdlg('Mark edited subject as done?', 'Mark edited subject as done?');
    if ~isempty(answer) && strcmpi(answer,'Yes')
        %-- mark current subject as done
        DS.edited(idx) = true;
        save(fnameCheckEditing, 'DS')
    end
    
    %--- ask whether user wants to continue
    if idx<height(DS)
        answer = questdlg('Continue with next subject?', sprintf('Edited %d out of %d subjects',idx,height(DS)));
        if ~isempty(answer) && strcmpi(answer,'Yes')
            idx = idx + 1;
        else
            idx = height(DS) + 1;
        end
    elseif idx==height(DS)
        % msgbox({'You edited all datasets!'; 'Thanks You!'});
        h = msgbox('Thank You!','You edited all datasets!');
        uiwait(h)
        idx = idx + 1;
    end
    
    
else
    %--- read subject table from Excel file
    DS = readtable(fnameSubjects);
    %--- check who was edited in the previous session
    if ~exist(fnameCheckEditing, 'file')
        DS.edited = false(height(DS),1);
    else
        temp = load(fnameCheckEditing);
        DSx = temp.DS;
        DS = outerjoin(DS,DSx(:,{'folder','fnameDat', 'edited'}), 'Type', 'left', 'Keys', {'folder','fnameDat'}, 'MergeKeys', true);
    end
    %--- randomize files / can make it optional /
    DS = DS(randperm(height(DS)), :);
    DS = sortrows(DS, 'edited', 'descend');
    idx = find(~DS.edited, 1);
    if isempty(idx)
        idx = height(DS) + 1;
    end
end

%% check presence of ROI file
% fnamesDat = cellfun(@(x,y) fullfile(x,y), DS.folder, DS.fnameDat, 'UniformOutput', false);
% DS.fnameROI = regexprep(fnamesDat, '.dat', '_ROI.mat')
% DS.fnameROIexist = cellfun(@exist, DS.fnameROI);
