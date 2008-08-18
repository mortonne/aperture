function h = plot_pow(values, dim, limits)
%PLOT_POW   Make a spectrogram from power data.
%   H = PLOT_POW(VALUES,DIM,LIMITS) plots the timeXfrequency
%   matrix VALUES in a colorplot, labeling the axes with
%   information from the DIM struct.  LIMITS gives the limits
%   of the color scale.
%

if ~exist('limits', 'var')
  limits = [];
end

clf reset

% get time information
x = getStructField(dim.time, 'avg');

% if only one time bin, need special x axis
if size(values,2)==1
	xlimit = [dim.time(1).MSvals(1) dim.time(end).MSvals(end)];
	x = [mean([xlimit(1) x]) mean([xlimit(2) x])];
	values = repmat(values,1,2);
	set(gca, 'XLim', xlimit)
end

% get frequency information
y = log10(getStructField(dim.freq, 'avg'));

% plot
if ~isempty(limits)
  h = imagesc(x, y, values, limits);
else
  h = imagesc(x, y, values);
end

axis xy

set(gca, 'YTick', log10([2 4 8 16 32 64 128]))
set(gca, 'YTickLabel', [2 4 8 16 32 64 128])
set(gca, 'LineWidth', 2)
xlabel('Time (ms)')
ylabel('Frequency (Hz)')

% colorbar
c = colorbar;
set(c, 'LineWidth', 2)
publishFig
