function h = topoplot(values, plotParams)
%h = topoplot(values, plotParams)
%
%TOPOPLOT - makes headplots from a vector, with views specified in
%plotParams.  Output is a vector of figure handles corresponding to
%each view.


if nargin<2
  plotParams = [];
end

plotParams = structDefaults(plotParams,  'pRange', [],  'splinefile', '~/eeg/GSN129_splines',  'views', {[280 35],[80 35]},  'elecLabel', 0,  'skipelec', []);

if ~exist(plotParams.splinefile,'file')
  error('Spline file does not exist')
end

if ~isempty(plotParams.pRange)
  sigVals = 1;
  p_range = plotParams.pRange;
else
  sigVals = 0;
end

warning('off', 'all');

% set up chans to remove so we don't spread into neck and face
chans_to_remove = [127 126 125 120 17 114 108 100 95 89 82 74 69 63 56 49 44 128];
totLen = 128;

if sigVals
  
  values(values>0) = values(values>0)/2;
  values(values<0) = (values(values<0)+1)/2+.5;
  p_range = p_range/2;
  
  colors{1,1} = [1.0 0.0 0.0];
  colors{1,2} = [1.0 0.8 0.8];
  colors{2,1} = [1.0 1.0 1.0];
  colors{2,2} = [1.0 1.0 1.0];
  colors{3,1} = [0.8 0.8 1.0];
  colors{3,2} = [0.0 0.0 1.0];
  
  vals(1,1) = p_range(2);
  vals(1,2) = p_range(1);
  vals(2,1) = p_range(1);
  vals(2,2) = 1-p_range(1);
  vals(3,1) = 1-p_range(1);
  vals(3,2) = 1-p_range(2);
  
  vals = norminv(vals);
  values = norminv(values);
  
else
  %map = jet(128);
  colors{1,1} = [1.0 0.0 0.0];
  colors{1,2} = [1.0 1.0 1.0];
  colors{2,1} = [1.0 1.0 1.0];
  colors{2,2} = [0.0 0.0 1.0];
  
  vals(1,1) = -max(values);
  vals(1,2) = 0;
  vals(2,1) = 0;
  vals(2,2) = max(values);
  
end

maplimits = [vals(1) vals(end)];
values(values<maplimits(1)) = maplimits(1);
values(values>maplimits(2)) = maplimits(2);

if exist('colors', 'var')
  map = [];
  for i=1:size(colors,1)
    colLen = fix(abs(diff(vals(i,:))/diff(maplimits))*(totLen+1));
    map = [map; makecolormap(colors{i,1}, colors{i,2}, colLen)];
  end
end

values(chans_to_remove) = mean(maplimits);

fig = 1;
for v=1:length(plotParams.views)
  figure(fig)
  clf reset
  
  headplot_mod(values, plotParams.splinefile, 'maplimits', maplimits, 'view', plotParams.views{v}, 'elec_noplot', chans_to_remove, 'colormap', map, 'labels', plotParams.elecLabel);
  h(v) = gcf;
  
  fig = fig + 1;
end

