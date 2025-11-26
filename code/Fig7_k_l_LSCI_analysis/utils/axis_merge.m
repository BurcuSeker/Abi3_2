function hf = axis_merge(hh, adjust, ncols)
% function axis_border(ax, adjust, ncols)
%
% ha        - axes handles (optional), if missing, then all open axes will be merged
% adjust    - logical, indicating, whether the axis limits should be made equal for all axes
% ncol      - number of columns for the output figure
%
%%
% addpath(genpath('/Volumes/Local/Matlab/panel-2.12/'))
%%
%--- example
% h = figure;
% h.Position = [350 100 1000 1000];
% p = panel(h);
% n = size(scoresWeighted,2);
% p.pack(n,n); %--- panel for each combination of variables in "scoresWeighted"
% for i=1:n
%     for j=1:n
%         p(i, j).select();
%         scatter(scoresWeighted(:,j), scoresWeighted(:,i), 20, 'filled');
%         if j==1
%             ylabel(varNames(1,i))
%         end
%         if i==n
%             xlabel(varNames(1,j))
%         end
%     end
% end

%% Find all existing axes in the objects in handles 'hh'
%--- if h is not provided, then find all existing figures
if ~exist('hh', 'var') || isempty(hh)
    hh = findobj('Type', 'Figure');
    hh = flipud(hh); %--- needed, because newest figure always is on top
end
%--- find axes in 'h' (h can already be handles to axes, this does not matter)
ha = [];
for i=1:length(hh)
    if strcmp(hh(i).Type, 'figure')
        haT = findobj(hh(i), 'Type', 'Axes');
        haT = flipud(haT); %--- needed, because newest axes always is on top
        ha = [ha; haT];
    else
        ha = [ha; findobj(hh(i), 'Type', 'Axes')];
    end
end

%% get handles of ancestor figures, to enable deletion at the end
% hfOld = ancestor(ha, 'figure');
%%
% position = reshape([ha.Position],4,[])';
% bh = max(position(:,3:4));
% % b = (bh(1) + bh(1)*0.05) * 2;
% % h = (bh(2) + bh(2)*0.05) * round(length(ha)/2);
% b = (bh(1)) * 2;
% h = (bh(2)) * round(length(ha)/2);
% bPixel = 1513;
% hPixelMax = 1340;
% hPixel = (h/b)*bPixel;
% if hPixel>hPixelMax
%    hPixel=hPixelMax; 
% end



%% Get axis limits for al axis, in order to make them all equal
xlT = [ha.XLim];
ylT = [ha.YLim];
xl  = [min(xlT), max(xlT)];
yl  = [min(ylT), max(ylT)];

%%
h = 1;
b = 4;
b = b * 2;
h = h * round(length(ha)/2);
bPixel = 1513;
hPixelMax = 1340;
hPixel = (h/b)*bPixel;
if hPixel>hPixelMax
   hPixel=hPixelMax; 
end
%% Create new figure 
hf = figure;
% hf.Position =[50 1 1513 1337];
hf.Position =[300 1 bPixel hPixel];

%% define the number of columns and rows
N = length(ha);
if exist('ncols', 'var') && ~isempty(ncols)
    nc = ncols;
else
    nc = ceil(sqrt(N));
end
nr = ceil(N/nc);
%---
p = panel(hf);
p.pack(nr,nc); 
% for i=1:n
%     for j=1:n
%         p(i, j).select();

%% define positions of axes using panel-2.12
iRow=0;
iCol=1;
for i=1:length(ha)
    %---
    % ht = subplot(nr, nc, i);
    if iRow<nr
        iRow=iRow+1;
    else
        iRow=1;
        iCol = iCol+1;
    end
    p(iRow, iCol).select();
    gcaT = gca;
    pPos(i,:) = gcaT.Position;
end
delete(p)

%% copy the axes to the new figure
for i=1:length(ha)
    %%
    ha(i) = copyobj(ha(i), hf);
    ha(i).Title.FontSize = 12;
    ha(i).Title.Interpreter = 'none';
    %ha(i).Position = ht.Position;
    ha(i).Position = pPos(i,:);
    if exist('adjust', 'var') && ~isempty(adjust) && adjust
        %--- adjust axis limits
        ha(i).XLim = xl;
        ha(i).YLim = yl;
    end
    %---
%     delete(ht)
end

%% Add Callback for WindowbuttonDownFcn
% set(hf,'WindowbuttonDownFcn',@clickcallback)
% function clickcallback(obj,evt)
%     persistent hac
%     switch get(obj,'SelectionType')
%         case 'normal'
%             %disp('normal click')
%             hac = gca;
%         case 'open'
%             disp('double click')
%             if ~isempty(hac.UserData) && ischar(hac.UserData)
%                 if exist(hac.UserData, 'file')
%                     pathResFig = hac.UserData;
%                 else
%                     pathResFig = regexprep(hac.UserData, {'/Volumes/','/'}, {'\\\\isdsynnas.srv.med.uni-muenchen.de\','\\'});
%                     if ~exist(pathResFig, 'file')
%                         warning('results figure not found')
%                         return
%                     end
%                 end
%                 hhf = open(pathResFig);
%                 hha = findobj(hhf, 'Type', 'Axes');
%                 % hha(end).Title.String = 'signal in 4 quadrants';
%                 hha(end).Title.String = hac.Title.String;
%             elseif ~isempty(hac)
%                 hhf = figure;
%                 hacT = copyobj(hac, hhf);
%                 hacT.Position = [0.05 0.05 0.9 0.9];
%             end
%     end
% end

%% remove the 'panel' specific callbacks from the figure
hf.ResizeFcn = [];
hf.CloseRequestFcn = 'closereq';

%% close the original figures, containing the copied axes
% for i=1:length(hfOld)
%     if ishandle(hfOld{i})
%         close(hfOld{i})
%     end
% end

end