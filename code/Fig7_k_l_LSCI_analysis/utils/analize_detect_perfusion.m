function [wndStim, wndBsln] = analize_detect_perfusion(ax, I2, roiSignal, fps)

%% define minimum duration for accepting overthreshold intervals as stimulation periods
%--- minimum duration 25 seconds (the attempted duration is 30 seconds)
wndStimMinWidth = round(25*fps);
fprintf('Minimum duration for accepting stimulation periods is 25 seconds (%d frames)\n', wndStimMinWidth)

%%
nF=size(I2,1);
c1 = round(roiSignal(1));
c2 = round(c1 + roiSignal(3));
if c1<1; c1=1; end
if c2>nF; c2=nF; end
I2crop = I2(c1:c2, : );
%%
% % I2 = reshape(I,[],size(I,3))';
% % I2 = reshape(I(2:3,2:3,:),[],size(I,3))';
% % I2f = filter_signal(I2, 4, 'bandpass', [0.01,1]);
% % I2f = filter_signal(I2, 4, 'highpass', 0.01);
% % I2f = detrend_polyfit(I2, 7);
% % I2f = detrend(I2);
%--- previously used good but complex alternative
% I2f = filter_twice_detrend(I2crop);
%--- simple but relatively stable
I2f = remove_trend_using_filter(I2crop, fps);

%%
IM = mean(I2f,2);
IMS = smooth_moving_average(IM,5);
%%
thr = multithresh(IMS);
%%
[idx1,idx2, ls] = find_positive_vector_segments(IMS>thr);
% [idx1,idx2, ls] = find_positive_vector_segments(vs>thr*1.5);


%% define baseline and stimulation periods

%%
wndStim= [idx1,idx2];
%---
% wndStim(ls<120 | idx1<200 | idx2>nF-50,:) = [];
wndStim(ls<wndStimMinWidth | idx1<170,:) = [];

%% remove epochs, if baseline intensity > stimulation intensity
idx1 = wndStim(:,1);
wndE1= [idx1-160,idx1-40];
% wndE1= [idx1-60,idx1-20];
% wndE2= [idx2+20,idx2+60];
% %%
wndStimM = average_epochs(IMS, wndStim);
wndE1M = average_epochs(IMS, wndE1);
% M3 = average_epochs(IMS, wndE2);
wndStim(wndStimM<=wndE1M, : ) = [];

%% select maximum stim periods, using a inter-stim-interval of approx. 1020 samples
% k = zeros(length(idx1),1);
% for i=1:length(idx1)
%     x = (idx1(i:end)-idx1(i))/1020;
%     x = round(x)-x;
%     %[x abs(x)<0.05];
%     k(i) = sum(abs(x)<0.1);
% end
% [~, ik] = max(k);
% x = (idx1(ik:end)-idx1(ik))/1020;
% x = round(x)-x;
% %[x abs(x)<0.05];
% idxL = abs(x)<0.05;
% wndExc = wndStim(~idxL,:);
% wndStim(~idxL,:) = [];



%% define baseline period considering sampling rate 
%--- shell be 30 seconds long, with an interval to the stimulation period of 10 seconds
idx1 = wndStim(:,1);
wndBsln = [idx1-round(40*fps),idx1-round(10*fps)];
isTooShort = wndBsln(:,1) < 1;
if any(isTooShort)
    warning('%d. Stimulation period too close to start of selected time-window! Baseline period cannot be defined!',find(isTooShort,1))
    wndBsln(isTooShort,:) = [];
    wndStim(isTooShort,:) = [];
end

%% draw signal time-course and highlight baseline/stimulation periods
% k=2;
% hf = figure;
%---
% subplot(k,1,1)
% hImage=imagesc(mean(imgPerf,3));
% axis equal tight
%---
% subplot(k,1,2)
% hImage=imagesc(DD(:,:,200));
% axis equal tight
%---
% ax = subplot(k,1,1);
% % hImage=plot(reshape(DD,[],size(DD,3))');
% hold on
% plot(I2crop)
% axis_border(ax,1)
% %-
% draw_rectangles(wndStim(:,1:2),ylim,'g',0.05)
% draw_rectangles(wndBsln,ylim,'b',0.05)
%---
% ax = subplot(k,1,2);
axes(ax)
hold off
plot([IM,IMS],'LineWidth',1); hold on
axis_border(ax,1)
%-
draw_rectangles(wndStim(:,1:2),ylim,'g',0.05)
% draw_rectangles(wndExc,ylim,'m',0.05)
draw_rectangles(wndBsln,ylim,'b',0.05)
%---
hold on;
plot(xlim, [thr thr], 'r')


%% show baseline and stimulation periods overlayed on signal time-course
% k=3;
% hf = figure;
% %---
% subplot(k,1,1)
% hImage=imagesc(mean(imgPerf,3));
% axis equal tight
% %---
% % subplot(k,1,2)
% % hImage=imagesc(DD(:,:,200));
% % axis equal tight
% %---
% ax = subplot(k,1,2);
% % hImage=plot(reshape(DD,[],size(DD,3))');
% hold on
% plot(I2)
% axis_border(ax,1)
% %-
% draw_rectangles(wndStim(:,1:2),ylim,'g',0.05)
% draw_rectangles(wndBsln,ylim,'b',0.05)
% %---
% ax = subplot(k,1,3);
% plot([IM,IMS],'LineWidth',1); hold on
% axis_border(ax,1)
% %-
% draw_rectangles(wndStim(:,1:2),ylim,'g',0.05)
% draw_rectangles(wndExc,ylim,'m',0.05)
% % draw_rectangles(wndBsln,ylim,'b',0.05)
% %---
% hold on;
% plot(xlim, [thr thr], 'r')

%% save figure
% addpath('/Volumes/Local/Matlab/altmany-export_fig-9ac0917/')
% % tdir = '/Volumes/Local/TEMP/burcu/';
% [pname, name] = fileparts(fnameIn);
% % [~, group] = fileparts(pname);
% % fnameFIG = fullfile(tdir, sprintf('fig_%s_%s.fig', group, name));
% % saveas(hf, fnameFIG)
% % fnamePNG = fullfile(tdir, sprintf('pic_%s_%s.png', group, name));
% fnamePNG = fullfile(pname, [name, '_ROI_stim.png']);
% export_fig(fnamePNG, '-r144', hf)
% % close(hf)
%% 
% img1 = nan(size(imgPerf,1),size(imgPerf,2), length(idx1));
% img2 = nan(size(imgPerf,1),size(imgPerf,2), length(idx1));
% for i=1:length(idx1)
%     img1(:,:,i) = mean(imgPerf(:,:,wndBsln(i,1):wndBsln(i,2)), 3);
%     img2(:,:,i) = mean(imgPerf(:,:,wndStim(i,1):wndStim(i,2)), 3);
% end
% %%
% img3 = img2./img1;
% img4 = img2-img1;
% %%
% img1m = montage_3D_to_2D(img1,5);
% img2m = montage_3D_to_2D(img2,5);
% img3m = montage_3D_to_2D(img3,5);
% img4m = montage_3D_to_2D(img4,5);
% 
% %% smooth images
% % sigma = 3;
% % img3mS = imgaussfilt(img3m, sigma);
% % % img1mS = imgaussfilt(img1m, sigma);
% % % img2mS = imgaussfilt(img2m, sigma);
% % % img3mS = img2mS./img1mS;
% 
% 
% %%
% figure;
% pp = prctile(img2m(:),[10,99]);
% subplot(4,1,1)
% % pp = prctile(img1m(:),[1,99])
% imagesc(img1m,pp)
% colorbar
% title('perfusion before stimulation')
% axis equal tight
% axis_border
% %-
% subplot(4,1,2)
% % pp = prctile(img2m(:),[1,99])
% imagesc(img2m,pp)
% colorbar
% title('perfusion during stimulation')
% axis equal tight
% axis_border
% %-
% subplot(4,1,3)
% pp = prctile(img3m(:),[20,80])
% imagesc(img3m,pp)
% colorbar
% title('ratio')
% axis equal tight
% axis_border
% %-
% subplot(4,1,4)
% pp = prctile(img4m(:),[5,95])
% imagesc(img4m,pp)
% % imagesc(img3mS,pp)
% colorbar
% title('difference')
% axis equal tight
% axis_border
% 
% 
