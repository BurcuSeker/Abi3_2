function hf = visualize_perfusion_raw(fnameIn, fps, readOnly)
% function hf = visualize_perfusion_raw(fnameIn, fps, readOnly)
%
% This script can be devided in two parts.
% 1. part:
% The script reads binary file (.dat) using PIMSoft Tools. It devides the
% field of view into a 4 x 4 grid and extracts then average timecourses 
% from the four central panels (the central 2 x 2 grid). In addition, it
% creates an average image across time.
% 2. part:
% The script displays the average image and the four average
% time courses and allows to the user to interactively position a spherical
% ROI on top of the average image and a TOI to limit the time segment which
% should be analysed.
%
% Input:
%   fnameIn     - file path to binary file (.dat)
%   fps         - acquisiton rate (frames per second)
%   readOnly    - logical, specifying whether the first part of the script
%               should be executed only.
%
% Output:
%   hf          - figure handle, produced by the second part of the script.
%                 Empty variable will be returned, if readOnly==true
%
%   The script automatically creates an output-File with suffix "_ROI.mat" 
%   with the average image, the four average timecourses (in the 1.part) 
%   and the spatial and temporal ROI (added in the 2. part).
%
%%
% clearvars
% clc
%% example input
% fnameIn = '/Volumes/Local/TEMP/burcu/sham/2 - 6 28 2018 11.11.21 AM.dat';
% fnameIn = '/Volumes/Local/TEMP/burcu/stroke/7 - 6 28 2018 4.25.13 PM.dat';
% readOnly = false;
% fps = 4.4; %--- Hz

%% check input
if ~exist('fps', 'var') || isempty(fps) || ~isnumeric(fps)
    warning('Input argument fps (frames-per-second) is missing and will be set to 4.4 Hz')
    fps = 4.4; %--- Hz
end

%%
[pname, name] = fileparts(fnameIn);
fnameROI = fullfile(pname, [name, '_ROI.mat']);

%%
if exist(fnameROI, 'file')
%     vars = whos('-file',fnameROI);
%     vars = {vars.name}';
    load(fnameROI)
end

if ~exist('I2', 'var') %--- assume that all required variables exist, if I2 exists
    %% add path to PIMsoftMatlab tools
    % addpath('/Volumes/Local/projects/Burcu/scripts/PIMSoftBinaryMatlab')
    
    %% open dat file
    data=PIMSoftBinary;     %--- create a variable of the PIMSoftBinary class
    data.OpenFile(fnameIn); %--- use the OpenFile method
       
    %% display information about dataset
    % [~, name, ext] = fileparts(fnameIn);
    % fprintf('\nReading file: >> %s <<\n', [name, ext])
    % fprintf('  frames n=%d\n', nF)
    disp(data)
    
    %% get some parameters
    CoherenceFactor=data.coherenceFactor;
    SignalGain=data.signalGain;
%     imgW = data.imageWidth;
%     imgH = data.imageHeight;
    nF=data.numberOfImages;
    
    %% read dataset and calculate perfusion
    tic
    imgPerf = nan(data.imageHeight,data.imageWidth, nF);
    windowSize = 1;
    for i=1:nF
        % ImVariance = data.getVarianceFrame(i);
        % ImIntensity = data.getDCFrame(i);
        % imgPerf(:,:,i)=calcPerfusion(ImVariance, ImIntensity, CoherenceFactor, SignalGain, windowSize);
        imgPerf(:,:,i)=calcPerfusion(data.getVarianceFrame(i), data.getDCFrame(i), CoherenceFactor, SignalGain, windowSize);
    end
    toc
    
    %% rotate images
    imgPerf = rot90(imgPerf);
    imgH = data.imageWidth;
    imgW = data.imageHeight;
    
    
    %% divide image into 4 x 4 blocks and average time-courses within each block
    tic
    blockW = floor(min(imgW,imgH)/4);
    
    %% 
    I = nan(4,4,size(imgPerf,3));
    for i=1:size(imgPerf,3)
        I(:,:,i) = blockAverageDownscale( imgPerf(:,:,i), blockW );
    end
    toc
    
    %% keep the core 2 x 2 blocks only and reshape 3D to 2D
    % I2 = reshape(I,[],size(I,3))';
    I2 = reshape(I(2:3,2:3,:),[],size(I,3))';
    
    %% calculate mean perfusion image, averaging across time
    imgMeanPerf = mean(imgPerf, 3);
    
    %% create ROI for the skull
    w = min(imgW,imgH);
    w1 = round(w/10);
    w2 = round(w/10*8);
    roiSkull = [w1, w1, w2, w2];
    %% create ROI for the signal periods
    prct = prctile(I2(:), [1 99]);
    roiSignal = [0, prct(1), nF, diff(prct)];
    
    %%
    save(fnameROI, 'imgMeanPerf', 'I2', 'imgW', 'imgH', 'nF', 'roiSkull', 'roiSignal')
    
end


%%
if exist('readOnly', 'var') && readOnly
    hf = [];
    return
end

%%
% I2f = filter_signal(I2, 4, 'bandpass', [0.01,1]);
% I2f = filter_signal(I2, 4, 'highpass', 0.01);
% I2f = filter_twice_detrend(I2);
% I2f = detrend_polyfit(I2, 7);
% I2f = detrend(I2);

%% create figure with 3 subplots, for average perfusion image, entire time courses, selected period of time courses (TOI)
hf = figure;
hf.Position = [718 522 1026 641];
%---
% ha1 = axes();
ha1 = subplot(3,1,1);
imagesc(imgMeanPerf);
axis equal tight
%---
ha2 = subplot(3,1,2);
% hImage=plot(reshape(DD,[],size(DD,3))');
hold on
plot(I2)
axis_border(ha2,1)

%% filter the time course inside the TOI
ha3 = subplot(3,1,3);
%--- without saving stimulation and baseline periods
% analize_detect_perfusion(ha3, I2, roiSignal, fps);
%--- optionally, save stimulation and baseline periods
[wndStim, wndBsln] = analize_detect_perfusion(ha3, I2, roiSignal, fps);
save(fnameROI, 'roiSignal', 'wndStim', 'wndBsln', '-append')

%% add ROI to 1. subplot
he = imellipse(ha1, roiSkull);
fcn = makeConstrainToRectFcn('imellipse', ha1.XLim, ha1.YLim);
setPositionConstraintFcn(he, fcn);
% setPositionConstraintFcn(he, makeConstrainToRectFcn('imellipse', ha1.XLim, ha1.YLim));
setFixedAspectRatioMode(he, true);


%% add TOI to 2. subplot
hr = imrect(ha2, roiSignal); %- create an interactive rectangle function
fcn = makeConstrainToRectFcn('imrect', ha2.XLim, ha2.YLim);  %- limit its location to stay within the image frame
setPositionConstraintFcn(hr, fcn); 


%% Create WindowsButtonUp Callback  / it is a dummy callback that initiate the ROI change when the user release the mouse button
set (hf, 'WindowButtonUpFcn', @roiChanged);

%% Create push button for saving ROI
% uicontrol('Style', 'pushbutton', 'String', 'Save',...
%     'Position', [20 20 50 20],...
%     'Callback', @save_ROI);
% 
%% Create push button for analize
% uicontrol('Style', 'pushbutton', 'String', 'Analize',...
%     'Position', [75 20 50 20],...
%     'Callback', @analize_ROI);

%%
D.he = he;
D.hr = hr;
D.ha3 = ha3;
D.roiSignal = hr.getPosition;
D.roiSkull = hr.getPosition;
D.fnameIn = fnameIn;
D.fnameROI = fnameROI;
% D.data = data;
D.imgMeanPerf = imgMeanPerf;
% D.imgPerf = imgPerf;
D.I2 = I2;
D.fps = fps;
hf.UserData = D;

end

%%
function roiChanged(object, eventdata)
%     fprintf('Hallo\n')
    D = object.UserData;
    roiSkull = D.he.getPosition;
    roiSignal = D.hr.getPosition;
    %---
    if any(D.roiSkull ~= roiSkull)
        fprintf('\nPosition of skull ROI changed:\n\t%0.f %0.f %0.f %0.f\n', roiSkull)
        fprintf('\tSaving new position\n')
        D.roiSkull = roiSkull;
        save(D.fnameROI, 'roiSkull', '-append')
        object.UserData = D;
    end
    %---
    if any(D.roiSignal ~= roiSignal)
        fprintf('\nPosition of signal ROI changed:\n\t%0.f %0.f %0.f %0.f\n', roiSignal)
        fprintf('\tSaving new position\n')
        D.roiSignal = roiSignal;
        [wndStim, wndBsln] = analize_detect_perfusion(D.ha3, D.I2, roiSignal, D.fps);
        save(D.fnameROI, 'roiSignal', 'wndStim', 'wndBsln', '-append')
        object.UserData = D;
    end
end

%%
% function save_ROI(object, eventdata)
%     % global hdrBG mask fnameMean %--- X mouseState imgBG
%     D = object.Parent.UserData;
%     roiSkull = D.he.getPosition;
%     roiSignal = D.hr.getPosition;
%     imgMeanPerf = D.imgMeanPerf;
%     I2 = D.I2;
%     %----
%     fprintf('\nSaving ROI coordinates:\n')
%     fprintf('Skull window: %.0f %.0f %.0f %.0f\n', roiSkull)
%     fprintf('Signal window: %.0f %.0f %.0f %.0f\n\n', roiSignal)
%     %---
%     save(D.fnameROI, 'roiSkull', 'roiSignal', 'imgMeanPerf', 'I2') %, '-v7.3')
%     % object.Parent.UserData = D;
% end
% 
% %%
% function analize_ROI(object, eventdata)
%     % global hdrBG mask fnameMean %--- X mouseState imgBG
%     D = object.Parent.UserData;
%     roiSkull = D.he.getPosition;
%     roiSignal = D.hr.getPosition;
%     %----
%     fprintf('\nDetecting stimulation periods and analyzing:\n')
%     fprintf('Skull window: %.0f %.0f %.0f %.0f\n', roiSkull)
%     fprintf('Signal window: %.0f %.0f %.0f %.0f\n\n', roiSignal)
%     %---
%     analize_detect_perfusion(D.fnameIn, D.I2, roiSignal)
%     %---
%     %save(D.fnameROI, 'roiSkull', 'roiSignal', 'imgMeanPerf', 'I2') %, '-v7.3')
%     % object.Parent.UserData = D;
% end
