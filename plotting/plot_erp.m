function plot_erp(erp1, erp2, p, erpParams, plotParams, saveDir, subjectid)
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
%                  REQUIRED
%                  .durationMS    - length of event in MS
%                  .offsetMS      - time in MS of start of event
%                  OPTIONAL
%                  .resampledRate - default = 500;
%                  .plotsPerFig   - cell array: {1} = number of
%                                   plots per figure, {2} =
%                                   arrangement of subplots 
%                                   (default = {[4], [2 2]})
%                  .removeTitle   - default = 0;
%                  .removeLabels  - default = 0;
%                  .removeLegend  - default = 0;
%        saveDir - directory to save plots in (if omitted, plots
%                  will not be saved)
%        subjectid - if included, will be used in the filenames
%                  when saving plots
% 
% OUTPUT: erp plots saved to saveDir
%

if nargin < 6
  subjectid = 'unknown';
end

if ~isfield(erpParams,'resampledRate')
  erpParams.resampledRate = 500;
end
if ~isfield(plotParams,'plotsPerFig')
  plotParams.plotsPerFig = {[4], [2 2]};
end
if ~isfield(plotParams,'erpFileTypes')
  plotParams.erpFileTypes = {'png'};
end
if ~isfield(plotParams,'rmErpTitle')
  plotParams.rmErpTitle = 0;
end
if ~isfield(plotParams,'rmErpLabels')
  plotParams.rmErpLabels = 0;
end
if ~isfield(plotParams,'rmErpLegend')
  plotParams.rmErpLegend = 0;
end

% close all open figures
close all
plots_per_fig = plotParams.plotsPerFig{1};
dimensions = plotParams.plotsPerFig{2};

% set some constants
moreSig = 0.001;
lessSig = 0.01;
fillcolMoreSig = [.3 .8 .3];
fillcolLessSig = [.5 .8 .5];
lineWidth = 1.1;

sampleRate = erpParams.resampledRate; % Hz (samples/second)

% prepare time axis
startMS = erpParams.offsetMS;
endMS = erpParams.offsetMS + erpParams.durationMS - 1;
timeStepMS = 1000/sampleRate;
timeMS = [startMS:timeStepMS:endMS];

% find corresponding samples
startSamp = ceil(((startMS - erpParams.offsetMS) * sampleRate/1000));
endSamp = ceil(((endMS - erpParams.offsetMS) * sampleRate/1000));
samples = [startSamp+1:endSamp];

% check if saving, prepare saveDir
if exist(saveDir)
  saveit = 1;  
  if ~exist(saveDir, 'dir')
    mkdir(saveDir);
  end
else saveit = 0;
end
  
f = figure(1);
%set(f, 'visible', 'off')
these_chans = [];

for chan_idx = 1:length(erpParams.channels) % electrodes
  channel = erpParams.channels(chan_idx);
  
  % if this figure has enough subplots...
  if mod(chan_idx-1, plots_per_fig)==0 & chan_idx~=1
    % if save dir specified, save current figure
    if saveit
      start_chan = these_chans(1);
      end_chan = these_chans(end);
      if ismember('eps', plotParams.erpFileTypes)	
	if start_chan~=end_chan
	  print(gcf,'-depsc', fullfile(saveDir, [subjectid, '_erp_' ... 
		    num2str(start_chan) '-' num2str(end_chan) '.eps']));
	else
	  print(gcf,'-depsc', fullfile(saveDir, [subjectid, '_erp_' ... 
		    num2str(start_chan) '.eps']));
	end
      end
      if ismember('png', plotParams.erpFileTypes)
	if start_chan~=end_chan
	  print(gcf,'-dpng', fullfile(saveDir, [subjectid, '_erp_' ... 
		    num2str(start_chan) '-' num2str(end_chan) '.png']));
	else
	  print(gcf,'-dpng', fullfile(saveDir, [subjectid, '_erp_' ... 
		    num2str(start_chan) '.png']));
	end
      end
    end
    these_chans = [];
    clf
  end
  
  if plots_per_fig>1

    % move to correct subplot
    subplot(dimensions(1), dimensions(2), mod(chan_idx-1, plots_per_fig) + 1);
  end
  these_chans = [these_chans channel];

  % for each sample, decide if significant
  pMoreSig = zeros(1,size(p,2));
  pLessSig = zeros(1,size(p,2));
  for sample = 1:size(p,2)
    thisSig = p(channel,sample);
    if thisSig<moreSig | thisSig>(1 - moreSig)
      pMoreSig(sample) = 1;
    elseif ( thisSig<lessSig & thisSig>=moreSig ) | ...
	   ( thisSig>(1 - lessSig) & thisSig<=(1 - moreSig) )
      pLessSig(sample) = 1;
    end
  end
  
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
  
  if plots_per_fig==1
    ticFontSize = 20;
    labelFontSize = 22;
    titleFontSize = 9;
    publishfig(gca,1,ticFontSize,labelFontSize);
    %publishFig(gca,0);
  end
 
end % channel
  
% if save dir specified, save the last remaining figure
if saveit
  if ismember('eps', plotParams.erpFileTypes)
    print(gcf,'-depsc', fullfile(saveDir, [subjectid, '_erp_' ... 
		    num2str(channel) '.eps']));
  end
  if ismember('png', plotParams.erpFileTypes)
    print(gcf,'-dpng', fullfile(saveDir, [subjectid, '_erp_' ... 
		    num2str(channel) '.png']));
  end
end

% Author: Matt Mollison
% Created: Mar 2005