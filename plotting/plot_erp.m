function h = plot_erp(timeMS, erp1, erp2, p)
%
%PLOT_ERP   Plot one or more ERPs, with or without significance.
%   H = PLOT_ERP(TIMEMS, ERP) creates a plot of voltage values in
%   ERP for times in vector TIMEMS, and returns handle H to the figure.
%
%   H = PLOT_ERP(TIMEMS, ERP1, ERP2) plots voltage values in ERP1
%   and ERP2 on the same axis.
%
%   H = PLOT_ERP(TIMEMS, ERP1, ERP2, P) plots two ERPs and shades
%   in regions that are significant.
%


if isempty(timeMS)
  timeMS = 1:length(erp1);
end

% set some constants
moreSig = 0.001;
lessSig = 0.01;
fillcolMoreSig = [.3 .8 .3];
fillcolLessSig = [.5 .8 .5];
lineWidth = 1.1;

clf

if exist('p', 'var')
  % get logicals for the two significance conditions
  pMoreSig = p < moreSig;
  pLessSig = p < lessSig & ~pMoreSig;
  
  % fill in the significant regions first
  fillSigDiff(timeMS, pMoreSig, erp1, erp2, fillcolMoreSig);
  fillSigDiff(timeMS, pLessSig, erp1, erp2, fillcolLessSig);
end

% plot the erps on top
hold on
h1 = plot(timeMS, erp1, 'r-');
h2 = plot(timeMS, erp2, 'b--');
minY = min(min(erp1), min(erp2));
maxY = max(max(erp1), max(erp2));

xlabel('Time (ms)')
ylabel('Voltage')

% plot the axes
ax = plot([0 0], [minY maxY], 'k--');
ay = plot([timeMS(1) timeMS(end)], [0 0], 'k--');

h = gcf;

function fillSigDiff(x, sig, y1, y2, fillcolor)

% pad x so we can count start and end right
diffvec = diff([0 sig 0]);

starts = find(diffvec(1:end-1)==1);
ends = find(diffvec(2:end)==-1);

nRegions = length(starts);
for i=1:nRegions
  l2r = starts(i):ends(i);
  r2l = fliplr(l2r);
  
  region_x = [x(l2r) x(r2l)];
  region_y = [y1(l2r) y2(r2l)];
  
  hMoreSig = fill(region_x, region_y, fillcolor);
  set(hMoreSig, 'edgecolor', fillcolor)
  hold on
end


% minY = min( [min(erp1(channel,samples)) min(erp2(channel,samples))] );
% maxY = max( [max(erp1(channel,samples)) max(erp2(channel,samples))] );
% difference = maxY - minY;
% minY = minY - 0.3*difference;
% maxY = maxY + 0.3*difference;

% if isnan(minY)
%   minY = -5;
%   maxY = 5;
% end

% axis([startMS endMS minY maxY]);
% if startMS>-500
%   xticks = [startMS 0:500:endMS];
% else
%   xticks = [startMS -500 0:500:endMS];
% end
% set(gca,'XTick',xticks);

% if plotParams.rmErpTitle==0
%   title_str = ['Channel ' num2str(channel)];
%   title(title_str);
% end

% if plotParams.rmErpLabels==0
%   xlabel('Time (ms)');
%   ylabel('Z-transformed Voltage');
% end

% if plotParams.rmErpLegend==0 & exist('hLessSig','var')
%   if exist('hMoreSig','var')
%     h = [hMoreSig hLessSig];
%     m = {['p < ',num2str(moreSig)],['p < ',num2str(lessSig)]};      
%   else  
%     h = [hLessSig];
%     m = {['p < ',num2str(lessSig)]};
%   end
%   legend(h,m);
% end

% ticFontSize = 20;
% labelFontSize = 22;
% titleFontSize = 9;
% publishfig(gca,1,ticFontSize,labelFontSize);

% % Author: Matt Mollison
% % Created: Mar 2005
