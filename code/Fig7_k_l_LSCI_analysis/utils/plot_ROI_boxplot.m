function hf = plot_ROI_boxplot(roi, roiCoordinates, DS)

hf = figure;
hf.Color = [1 1 1];
hf.Position = [1025 415 560 922];
%---
nRoi = size(roi,2);
%---
for iRoi=1:nRoi
    %---
    ha = subplot(nRoi,1,iRoi);
    hold on
    g1 = grp2idx(DS.day);
    g2 = 2./grp2idx(DS.group);
    boxplot(roi(:,iRoi), [g1, g2], 'ColorGroup', g2, 'FactorGap',[15,0], 'Widths',0.8)
    ylabel('signal increase [%]')
    title(sprintf('ROI in posion: row=%d, col=%d', roiCoordinates(iRoi,:)))
end