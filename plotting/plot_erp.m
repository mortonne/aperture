function plot_erp(MSvals, erp1, erp2, p)
%
%PLOT_ERP - makes plots of erp's of two different event types, with
%significant differences shaded in
% 
% FUNCTION: plot_erp(erp1, erp2, p, params, saveDir, subjectid)
%
% INPUT: erp1    - erp data of format Channels X Samples
%        erp2    - erp's from second event condition
%        p       - p-values for significance of difference between
%                  erp1 and erp2
%        params  - struct with fields:
%                  .removeTitle   - default = 0;
%                  .removeLabels  - default = 0;
%                  .removeLegend  - default = 0;

% set some constants
moreSig = 0.001;
lessSig = 0.01;
fillcolMoreSig = [.3 .8 .3];
fillcolLessSig = [.5 .8 .5];
lineWidth = 1.1;

clf

% get logicals for the two significance conditions
pMoreSig = p < moreSig;
pLessSig = p < lessSig & ~pMoreSig;
  
% make matrices of beginning and end of significant regions
startMoreSig = find(diff(pMoreSig) == 1);
endMoreSig = find(diff(pMoreSig) == -1);
startLessSig = find(diff(pLessSig) == 1);
endLessSig = find(diff(pLessSig) == -1);

% make sure start and end points get counted because of how diff works
if pMoreSig(1) == 1
  startMoreSig = [1 startMoreSig];
end
if pMoreSig(end) == 1
  endMoreSig(end+1) = length(pMoreSig);
end
if pLessSig(1) == 1
  startLessSig = [1 startLessSig];
end
if pLessSig(end) == 1
  endLessSig(end+1) = length(pLessSig);
end

% draw and fill in polygon for more significant regions
for i=1:length(startMoreSig)
  left2right = [startMoreSig(i):endMoreSig(i)];
  right2left = fliplr(left2right);
  % make x & y coordinates of vertices
  x = [timeMS(left2right) timeMS(right2left)];
  y = [erp1(channel,left2right) erp2(channel,right2left)];
  % fill in the polygon
  hMoreSig = fill(x,y,fillcolMoreSig);
  set(hMoreSig,'edgecolor',fillcolMoreSig)
  hold on
end

% draw and fill in polygon for less significant regions
for i=1:length(startLessSig)
  left2right = [startLessSig(i):endLessSig(i)];
  right2left = fliplr(left2right);
  % make x & y coordinates of vertices
  x = [timeMS(left2right) timeMS(right2left)];
  y = [erp1(channel,left2right) erp2(channel,right2left)];
  % fill in the polygon
  hLessSig = fill(x,y,fillcolLessSig);
  set(hLessSig,'edgecolor',fillcolLessSig)
  hold on
end

minY = min( [min(erp1(channel,samples)) min(erp2(channel,samples))] );
maxY = max( [max(erp1(channel,samples)) max(erp2(channel,samples))] );
difference = maxY - minY;
minY = minY - 0.3*difference;
maxY = maxY + 0.3*difference;

if isnan(minY)
  minY = -5;
  maxY = 5;
end

hold on
% plot axes
plot([startMS endMS], [0 0], 'k--');
plot([0 0], [minY maxY], 'k--');

ht = plot(timeMS,erp1(channel,samples),'r','LineWidth',lineWidth);
hl = plot(timeMS,erp2(channel,samples),'b--','LineWidth',lineWidth);

axis([startMS endMS minY maxY]);
if startMS>-500
  xticks = [startMS 0:500:endMS];
else
  xticks = [startMS -500 0:500:endMS];
end
set(gca,'XTick',xticks);

if plotParams.rmErpTitle==0
  title_str = ['Channel ' num2str(channel)];
  title(title_str);
end

if plotParams.rmErpLabels==0
  xlabel('Time (ms)');
  ylabel('Z-transformed Voltage');
end

if plotParams.rmErpLegend==0 & exist('hLessSig','var')
  if exist('hMoreSig','var')
    h = [hMoreSig hLessSig];
    m = {['p < ',num2str(moreSig)],['p < ',num2str(lessSig)]};      
  else  
    h = [hLessSig];
    m = {['p < ',num2str(lessSig)]};
  end
  legend(h,m);
end

ticFontSize = 20;
labelFontSize = 22;
titleFontSize = 9;
publishfig(gca,1,ticFontSize,labelFontSize);

% Author: Matt Mollison
% Created: Mar 2005