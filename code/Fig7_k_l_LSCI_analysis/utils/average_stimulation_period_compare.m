function hf = average_stimulation_period_compare(fnameIn, fps, wndStimCrop, excludeStimulation, wh)

%%
% clc
% clearvars
%% example input for testing
% % % fnameIn = '/Volumes/Local/TEMP/burcu/test/1 - 6 28 2018 10.14.58 AM.dat'
% % % fnameIn = '/Volumes/BD-Plesnila/Susana Valero/NVC 5,7,14d/Binary_recordings/14dSham/SV011019_2_14dSham.dat'
% fnameIn = '/Volumes/BD-Plesnila/Susana Valero/NVC 5,7,14d/Binary_recordings/14dSham/SV300919_4_14dSham.dat';
% fps = 4.4; %--- frames per second
% wndStimCrop = [10,30]; %--- define restricted time window within the automatically detected stimulation period (in seconds from stimulation onset)
% excludeStimulation = NaN;
%% Specify desired width/height for resized images (in pixel)
% wh=120; %--- used for Susi's PhD thesis
if ~exist('wh','var') || isempty(wh) || ~isnumeric(wh)
    wh=120;
end

%%
%--- input files
[pname, name] = fileparts(fnameIn);
fnameROI = fullfile(pname, [name, '_ROI.mat']);
whStr = sprintf('%d', wh);
%--- output files
% fnameOut = fullfile(pname, [name, '_results_k', kStr, '.mat']);
% fnamePNG = fullfile(pname, [name, '_results_k', kStr, '.png']);
% fnameOut = fullfile(pname, [name, '_results_reg2Pass_k', kStr, '.mat']);
% fnamePNG = fullfile(pname, [name, '_results_reg2Pass_k', kStr, '.png']);
fnameOut = fullfile(pname, [name, '_results_realigned_k', whStr, '.mat']);
fnamePNG = fullfile(pname, [name, '_results_realigned_k', whStr, '.png']);
%---
fnameRealignPNG = fullfile(pname, [name, '_realignment_QC', '.png']);

%% load ROI info
if ~exist(fnameROI, 'file')
    error('file with ROI info is missing')
end
%---
% vars = whos('-file',fnameROI);
% vars = {vars.name}';
load(fnameROI)


%% copy the original stimulation periods
wndStimOrig = wndStim;
%% exclude stimulation periods, if desired by user
if exist('excludeStimulation', 'var') && isnumeric(excludeStimulation) && ~isnan(excludeStimulation)
    wndStim(excludeStimulation, :) = [];
    wndBsln(excludeStimulation, :) = [];
end

%% crop stimulation periods, if desired
if exist('wndStimCrop', 'var') && isnumeric(wndStimCrop)
    fprintf('Cropping stimulation periods to range from %d to %d seconds\n', wndStimCrop(1), wndStimCrop(2))
    
    %--- compute desired offset to start of stimulation period in frames
    wndStimOffsetStartF = round(wndStimCrop(1) * fps);
    wndStimOffsetStopF = round(wndStimCrop(2) * fps)-1;
    
    %--- compare desired window start/stop to actual window stop
    idx1 = diff(wndStim,1,2) > wndStimOffsetStartF;
    idx2 = diff(wndStim,1,2) > wndStimOffsetStopF;
    if ~all(idx1)
        warning('Some stimulation periods stop alread before the desired start time')
    end
    if ~all(idx2)
        warning('Some stimulation periods stop alread before the desired stop time')
    end
    %--- shift the start/stop time, if possible
    wndStart = wndStim(:,1);
    wndStim(idx1,1) = wndStart(idx1) + wndStimOffsetStartF;
    wndStim(idx2,2) = wndStart(idx2) + wndStimOffsetStopF;
    
    %--- exclude stimulation periods, if the cropping could not be done as desired
    if ~all(idx1 & idx2)
        warning('Excluding stimulation periods, which were to short for cropping')
        idx = idx1 & idx2;
        wndStim(~idx, :) = [];
        wndBsln(~idx, :) = [];
    end
    
end

%%
wndStimOrig = compare_intervals(wndStimOrig, wndStim);

%% add path to PIMsoftMatlab tools
% addpath('/Volumes/Local/projects/Burcu/scripts/PIMSoftBinaryMatlab')

%%
data=PIMSoftBinary;     %--- create a variable of the PIMSoftBinary class
data.OpenFile(fnameIn); %--- use the OpenFile method

%%
CoherenceFactor=data.coherenceFactor;
SignalGain=data.signalGain;
% imgW = data.imageWidth;
% imgH = data.imageHeight;
nF=data.numberOfImages;

%% display information about dataset
[~, name, ext] = fileparts(fnameIn);
fprintf('\nReading file: >> %s <<\n', [name, ext])
% fprintf('  frames n=%d\n', nF)
disp(data)

%% read dataset
ht=tic;
imgPerf = nan(data.imageHeight,data.imageWidth, nF);
windowSize = 1;
for i=1:nF
    % ImVariance = data.getVarianceFrame(i);
    % ImIntensity = data.getDCFrame(i);
    % imgPerf(:,:,i)=calcPerfusion(ImVariance, ImIntensity, CoherenceFactor, SignalGain, windowSize);
    imgPerf(:,:,i)=calcPerfusion(data.getVarianceFrame(i), data.getDCFrame(i), CoherenceFactor, SignalGain, windowSize);
end
toc(ht)

%% rotate images
imgPerf = rot90(imgPerf);

%% keep only signal in roiSiganl
c1 = round(roiSignal(1));
c2 = round(c1 + roiSignal(3));
if c1<1; c1=1; end
if c2>nF; c2=nF; end
%--- crop signal
imgPerf = imgPerf(:,:, c1:c2);
%--- 
nF = size(imgPerf,3);

%% Realign images
[optimizer, metric] = imregconfig('monomodal');
imgPerfMean = mean(imgPerf, 3);

%% Find a good frame as reference for the first pass
ht=tic;
nTry = 15;
fprintf('Looking for a good reference frame... ')
idxTry = round(linspace(1,nF,nTry+2));
idxTry = idxTry(2:end-1);
imgRefT  = imgPerf(:,:,idxTry);
for i=1:length(idxTry)
    imgRefT(:,:,i) = imgaussfilt(imgRefT(:,:,i),2);
    imgRefT(:,:,i) = imgRefT(:,:,i)/max(max(imgRefT(:,:,i)));
end
%---
tform = cell(nTry,nTry-1);
for i=1:nTry
    k=0;
    for j=1:nTry
        if j~=i
            k=k+1;
            imgTemp = imhistmatch(imgRefT(:,:,j), imgRefT(:,:,i));
            tform{i,k} = imregtform(imgTemp, imgRefT(:,:,i), 'rigid', optimizer, metric);
            % imgPerfR1(:,:,i) = imwarp(imgPerf(:,:,i),tform{i},'OutputView', R);
        end
    end
end
%--- calculate displacement for a set of 5 points (pp)
r = size(imgPerf,1)/2;
pp = [0 0; 0 r; r 0; 0 r; r r; r/2 r/2];
dd = nan(nTry,nTry-1);
for i=1:nTry
    for j=1:nTry-1
        temp = transformPointsForward(tform{i,j}, pp);
        temp = sum((temp-pp).^2,2).^0.5;
        dd(i,j) = mean(temp);
    end
end
%---
[~, iBest] = min(mean(dd,2));
idxImgFixed1 = idxTry(iBest);
fprintf('\n  Selected frame with index = %d\n',idxImgFixed1)
%---
toc(ht)
%% plot displacement for each of the nTry candiate frames
% figure;
% for i=1:10
%     subplot(11,1,i)
%     plot(dd(i,:))
% end
% subplot(11,1,11)
% plot(mean(dd,2),'r')


%%
warning('off','all')
%---
ht=tic;
fprintf('Realignment: 1. path, aligning to first image\n')
t=0;
tform = cell(nF,1);
R = imref2d(size(imgPerfMean));
imgPerfR  = imgPerf;
imgPerfR1 = imgPerf;
for i=1:nF
    imgPerfR(:,:,i) = imgaussfilt(imgPerfR(:,:,i),2);
    imgPerfR(:,:,i) = imgPerfR(:,:,i)/max(max(imgPerfR(:,:,i)));
end
imgFixed1 = imgPerfR(:,:,idxImgFixed1);
warnMsgAll = cell(0);
warnIdAll = cell(0);
W1 = nan(nF,1);
% figure;
for i=1:nF
    lastwarn('')
    if mod(i,20)==0
       fprintf(repmat('\b',1,t))
       t=fprintf('% 5d out of %d images\n', i, nF);
    end
    % imgPerfR(:,:,i) = imgaussfilt(imgPerfR(:,:,i),2);
    % imgPerfR(:,:,i) = imgPerfR(:,:,i)/max(max(imgPerfR(:,:,i)));
    imgTemp = imhistmatch(imgPerfR(:,:,i), imgFixed1);
    tform{i} = imregtform(imgTemp, imgFixed1, 'rigid', optimizer, metric);
    imgPerfR1(:,:,i) = imwarp(imgPerf(:,:,i),tform{i},'OutputView', R);
    %-
    [warnMsg, warnId] = lastwarn;
    if ~isempty(warnMsg)
        idx = find(strcmp(warnId,warnIdAll));
        if isempty(idx)
            warnIdAll{end+1,1} = warnId;
            warnMsgAll{end+1,1} = warnMsg;
            idx = length(warnIdAll);
        end
        W1(i) = idx;
    end
    % imshowpair(imgPerfR(:,:,i), imgPerfR(:,:,i),'montage') %'Scaling','joint')
end
toc(ht)

%% calculate translation and angle
%- follows suggestion on: https://math.stackexchange.com/questions/13150/extracting-rotation-scale-values-from-2d-transformation-matrix
%- rotation angle can be calculated in two ways:
%-      atan2(-x.T(2,1),x.T(1,1))
%-      atan2(x.T(1,2),x.T(2,2))
% T1 = cellfun(@(x) [x.T(3,1), x.T(3,2), atan2(-x.T(2,1),x.T(1,1))/pi*180], tform(2:end), 'UniformOutput',false);
T1 = cellfun(@(x) [x.T(3,1), x.T(3,2), atan2(-x.T(2,1),x.T(1,1))/pi*180], tform, 'UniformOutput',false);
T1 = cat(1,T1{:});
% T1 = [0 0 0; T1];
%%
%
mt = mean(T1);
st = std(T1);
T1out = bsxfun(@minus, T1, mt);
T1out = bsxfun(@minus, abs(T1out), 4 * st) > 0;
T1out = T1out | [false(1,3); T1out(1:end-1,:)] | [T1out(2:end,:); false(1,3)];
T1out = any(T1out,2);
% T1in = T1;
% T1in(T1out,:) = nan;
T1red = T1;
T1red(~T1out,:) = nan;
%
% figure;
% plot(T1in); hold on
% plot(T1red,'rx')

%%
%---
imgPerfR1Mean = mean(imgPerfR1(:,:,~T1out), 3);
imgFixed2 = imgaussfilt(imgPerfR1Mean,1);
imgFixed2 = imgFixed2/max(max(imgFixed2));
%%
%---
ht=tic;
fprintf('Realignment: 2. path, aligning to mean\n')
t=0;
tform = cell(nF,1);
W2 = nan(nF,1);
for i=1:nF
    lastwarn('')
    if mod(i,20)==0
       fprintf(repmat('\b',1,t))
       t=fprintf('% 5d out of %d images\n', i, nF);
    end
    imgPerfR(:,:,i) = imhistmatch(imgPerfR(:,:,i), imgFixed2);
    tform{i} = imregtform(imgPerfR(:,:,i), imgFixed2, 'rigid', optimizer, metric);
    imgPerfR(:,:,i) = imwarp(imgPerf(:,:,i),tform{i},'OutputView', R);
    [warnMsg, warnId] = lastwarn;
    if ~isempty(warnMsg)
        idx = find(strcmp(warnId,warnIdAll));
        if isempty(idx)
            warnIdAll{end+1,1} = warnId;
            warnMsgAll{end+1,1} = warnMsg;
            idx = length(warnIdAll);
        end
        W2(i) = idx;
    end
end
toc(ht)
%---
warning('on','all')

%% calculate translation and angle
%- follows suggestion on: https://math.stackexchange.com/questions/13150/extracting-rotation-scale-values-from-2d-transformation-matrix
%- rotation angle can be calculated in two ways:
%-      atan2(-x.T(2,1),x.T(1,1))
%-      atan2(x.T(1,2),x.T(2,2))
T2 = cellfun(@(x) [x.T(3,1), x.T(3,2), atan2(-x.T(2,1),x.T(1,1))/pi*180], tform, 'UniformOutput',false);
T2 = cat(1,T2{:});
%%
mt = mean(T2);
st = std(T2);
T2out = bsxfun(@minus, T2, mt);
T2out = bsxfun(@minus, abs(T2out), 4 * st) > 0;
T2out = T2out | [false(1,3); T2out(1:end-1,:)] | [T2out(2:end,:); false(1,3)];
T2out = any(T2out,2);
% T2in = T2;
% T2in(T2out,:) = nan;
T2red = T2;
T2red(~T2out,:) = nan;

%%
imgPerfR2Mean = mean(imgPerfR(:,:,~T2out), 3);

%%
hf = figure;
hf.Units='pixels';
hf.Position = [100 200 1200 800];
subplot(3,5,1)
imagesc(imgFixed1), axis equal tight
title('Reference 1. pass (1. frame)')
subplot(3,5,2)
imagesc(imgFixed2), axis equal tight
title('Reference 2. pass')
subplot(3,5,3)
imagesc(imgPerfMean), axis equal tight
title('mean before aligning')
subplot(3,5,4)
imagesc(imgPerfR1Mean), axis equal tight
title('mean after 1. pass')
subplot(3,5,5)
imagesc(imgPerfR2Mean), axis equal tight
title('mean after 2. pass')

%---
subplot(3,1,2)
% plot(T1)
plot(T1); hold on
plot(T1red,'rx')
xline(idxImgFixed1,'k');
legend({'tx [pixel]','ty [pixel]','\psi [degree]'})
title('1. pass')
%---
subplot(3,1,3)
% plot(T2)
plot(T2); hold on
plot(T2red,'rx')
xline(idxImgFixed1,'k');
legend({'tx [pixel]','ty [pixel]','\psi [degree]'})
title('2. pass')

%%
% addpath('/Volumes/Local/Matlab/altmany-export_fig-9ac0917/')
export_fig(fnameRealignPNG, '-r144', hf)
saveas(hf, regexprep(fnameRealignPNG, '\.png', '.fig'))
close(hf)

%% Continue workingwith the realigned image
imgPerf(:,:,~T2out) = imgPerfR(:,:,~T2out);


%% Convert skull ROI coordinates to left bottom and top right corner
%--- skull ROI coordinates are saved as [left, bottom, width, height]. 
diameter = round(roiSkull(3)); %--- width and hight are the same
roiSkull(4) = roiSkull(2)+diameter;
roiSkull(3) = roiSkull(1)+diameter;
roiSkull([1,2]) = ceil(roiSkull([1,2]));
roiSkull([3,4]) = floor(roiSkull([3,4]));
% roiSkull(3)-roiSkull(1)
% roiSkull(4)-roiSkull(2)

%% cut out skull ROI
% imgPerf = imgPerf(roiSkull(1):roiSkull(3),roiSkull(2):roiSkull(4),:);
imgPerf = imgPerf(roiSkull(2):roiSkull(4),roiSkull(1):roiSkull(3),:);


%% resize image to a common height and width, to allow for averaging across patients
% wh=120; %--- desired width and height (in pixel)
nF = size(imgPerf,3);
imgPerfTemp = nan(wh,wh,nF);
for i=1:nF
    imgPerfTemp(:,:,i) = imresize(imgPerf(:,:,i), [wh wh]); %, 'nearest')
end

%% reshape to 2D matrix (time x pixel)
I2 = reshape(imgPerfTemp,[],nF)';
% imgMeanPerf = mean(imgPerf, 3);

%%
% ht = tic;
% I2f = filter_signal(I2, 4, 'bandpass', [0.01,1]);
% I2f = filter_signal(I2, 4, 'highpass', 0.01);
% I2f = filter_twice_detrend(I2);
[~, I2f] = remove_trend_using_filter(I2, fps); 
% I2f = detrend_polyfit(I2, 7);
% I2f = detrend(I2);
% toc(ht)

%% reshape to original 3D matrix
imgPerfF = reshape(I2f', wh, wh, []);


%% create mask for skull ROI with 4 quadrants
%--- radius and centroid
sz = size(imgPerfF);
radius = sz(1)/2 +0.5;
centroid = radius;
% centroid(1) = roiSkull(2)+radius;
% centroid(2) = roiSkull(1)+radius;
%--- define a circular mask and it's 4 quadrants
imgMask = zeros(sz(1:2));
for i=1:sz(1)
    for j=1:sz(2)
        dist = sum(([i j]-centroid).^2)^.5;
        if dist <= radius
            if i<centroid && j<centroid
                imgMask(i,j) = 1;
            elseif i>centroid && j<centroid
                imgMask(i,j) = 2;
            elseif i>centroid && j>centroid
                imgMask(i,j) = 3;
            elseif i<centroid && j>centroid
                imgMask(i,j) = 4;
            end
        end
    end
end

%%
% figure;
% imagesc(imgMask)
% axis equal tight
% colormap(autumn)
% colorbar()
% 
% %%
% figure;
% ax = axes();
% imagesc(mean(imgPerfF,3))
% axis equal tight
% hold on
% contour(imgMask==1, 1, 'LineWidth', 2, 'LineColor', ax.ColorOrder(2,:))
% contour(imgMask==2, 1, 'LineWidth', 2, 'LineColor', ax.ColorOrder(3,:))
% contour(imgMask==3, 1, 'LineWidth', 2, 'LineColor', ax.ColorOrder(4,:))
% contour(imgMask==4, 1, 'LineWidth', 2, 'LineColor', ax.ColorOrder(5,:))



%% extract ROI signal time-course
roiSig = zeros(size(I2f,1),4);
for i=1:4
    roiSig(:,i) = mean(I2f(:, imgMask(:)==i), 2);
end

%%
% figure;
% ax = axes();
% hold on
% ax.ColorOrderIndex = 2;
% plot(roiSig)
% draw_rectangles(wndStim(:,1:2),ylim,'g',0.05)
% draw_rectangles(wndBsln,ylim,'b',0.05)

%% censoring spiky artifacts
%--- remove frames within stimulation periods if signal > MEAN + 5 * STD (MEAN and STD are calculated within the same stimulation period)
nTOI = size(wndStim,1);
censoring = false(size(roiSig));
wndStimL =  false(size(roiSig,1),1);
for i=1:nTOI
    toiM = mean(roiSig(wndStim(i,1):wndStim(i,2), :));
    toiS = std(roiSig(wndStim(i,1):wndStim(i,2), :));
    wndStimL(wndStim(i,1):wndStim(i,2)) = true;
    for j=1:4
        censoring(wndStim(i,1):wndStim(i,2), j) = roiSig(wndStim(i,1):wndStim(i,2), j) > toiM(j)+toiS(j)*5;
    end
end
%% censor also spikes outside stimulation period
%--- remove framses if signal > MAX within all stimulation periods
for j=1:4
    mm = max(roiSig(wndStimL, j));
    censoring(roiSig(:, j) > mm) = true;
end
%% censor frames if censored in any of the 4 quadrants 
censoring = any(censoring,2);
%% censor also one frame backwards and forwards
censoring(1:end-1) = censoring(1:end-1) | censoring(2:end);
censoring(2:end) = censoring(2:end) | censoring(1:end-1);
%% censor also frames with problems during realignment
censoring = censoring | T2out;
%%
% figure;
% %%
% imagesc(imgPerf(:,:,1)); axis tight equal; colorbar
%%
roiSig(censoring,:) = nan;
%%
imgPerfFC = imgPerfF;
imgPerfFC(:,:,censoring) = nan;

%% average image within Baseline and Stimulation periods
imgBl = nan(size(imgPerfFC,1),size(imgPerfFC,2), nTOI);
imgStim = nan(size(imgPerfFC,1),size(imgPerfFC,2), nTOI);
for i=1:nTOI
    imgBl(:,:,i) = mean(imgPerfFC(:,:,wndBsln(i,1):wndBsln(i,2)), 3, 'omitnan');
    imgStim(:,:,i) = mean(imgPerfFC(:,:,wndStim(i,1):wndStim(i,2)), 3, 'omitnan');
end

%% SAVE THE AVERAGE IMAGE FOR BASLINE AND STIMULATION PERIOD
save(fnameOut, 'imgBl', 'imgStim')



%% PLOTTING

%% calculate relative and absolute difference between stimulation and baseline periods
img3 = imgStim./imgBl;
img4 = imgStim-imgBl;

%%
img1m = montage_3D_to_2D(imgBl,nTOI);
img2m = montage_3D_to_2D(imgStim,nTOI);
img3m = montage_3D_to_2D(img3,nTOI);
img4m = montage_3D_to_2D(img4,nTOI);
imgMaskM = repmat(imgMask, 1, nTOI);


%% smooth images
% sigma = 3;
% img3mS = imgaussfilt(img3m, sigma);
% % img1mS = imgaussfilt(img1m, sigma);
% % img2mS = imgaussfilt(img2m, sigma);
% % img3mS = img2mS./img1mS;


%%
hf = figure;
hf.Visible = 'off';
hf.Position = [1445 333 967 1012];
%---
% ax = subplot(5,3,1);
% imagesc(mean(imgPerfF,3))
% axis equal tight
% hold on
% contour(imgMask==1, 1, 'LineWidth', 2, 'LineColor', ax.ColorOrder(2,:))
% contour(imgMask==2, 1, 'LineWidth', 2, 'LineColor', ax.ColorOrder(3,:))
% contour(imgMask==3, 1, 'LineWidth', 2, 'LineColor', ax.ColorOrder(4,:))
% contour(imgMask==4, 1, 'LineWidth', 2, 'LineColor', ax.ColorOrder(5,:))
%--- subplot 1
ax = subplot(5,1,1);
hold on
mi = min(roiSig(:));
ma = max(roiSig(:));
ra = ma-mi;
mi = mi-ra*10/100;
ma = ma+ra*10/100;
ylimT = [mi, ma];
if ~any(isnan(wndStimOrig(:)))
    draw_rectangles(wndStimOrig(:,1:2),ylimT,'k',0.2)
end
draw_rectangles(wndStim(:,1:2),ylimT,'g',0.2)
draw_rectangles(wndBsln,ylimT,'b',0.2)
ax.ColorOrderIndex = 2;
plot(roiSig)
ylim(ylimT)
title(['subject: ' name], 'Interpreter', 'none')
axis_border(ax, 1)
%--- subplot 2
pp = prctile(img2m(:),[10,99]);
subplot(5,1,2);
% pp = prctile(img1m(:),[1,99])
imagesc(img1m,pp)
colorbar
title('perfusion during baseline')
axis equal tight
axis_border
hold on
contour(imgMaskM==1, 1, 'LineWidth', 2, 'LineColor', ax.ColorOrder(2,:))
contour(imgMaskM==2, 1, 'LineWidth', 2, 'LineColor', ax.ColorOrder(3,:))
contour(imgMaskM==3, 1, 'LineWidth', 2, 'LineColor', ax.ColorOrder(4,:))
contour(imgMaskM==4, 1, 'LineWidth', 2, 'LineColor', ax.ColorOrder(5,:))

%--- subplot 3
subplot(5,1,3);
% pp = prctile(img2m(:),[1,99])
imagesc(img2m,pp)
colorbar
title('perfusion during stimulation')
axis equal tight
axis_border

%--- subplot 4
img3mp = img3m*100-100; %--- convert to percentage
ax4 = subplot(5,1,4);
pp = [0 15]; %--- show 100% to 115%
% pp(1) = 100; %--- show from 100% (baseline) to 80th percentile
% pp(2) = prctile(img3mp(:),80);
% if pp(2)<=pp(1)
%     pp(2) = max(img3mp(:));
% end
imagesc(img3mp,pp);
colormap(ax4,autumn)
colorbar
title('difference [%]')
axis equal tight
axis_border

%--- subplot 5
ax5 = subplot(5,1,5);
pp = prctile(img4m(:),[5,95]);
imagesc(img4m,pp)
% imagesc(img3mS,pp)
colormap(ax5,autumn)
colorbar
title('absolute difference')
axis equal tight
axis_border


%%
% addpath('/Volumes/Local/Matlab/altmany-export_fig-9ac0917/')
export_fig(fnamePNG, '-r144', hf)
saveas(hf, regexprep(fnamePNG, '\.png', '.fig'))
close(hf)



