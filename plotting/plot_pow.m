function h = plot_pow(values, freq, time, limits)
%PLOT_POW   Make a spectrogram from power data.
%   H = PLOT_POW(VALUES,FREQ,TIME,LIMITS) plots the frequencyXtime
%   matrix VALUES in a colorplot. FREQ is a vector that gives the
%   frequency in Hertz of each row in VALUES, while TIME gives times
%   in miliseconds for each column of VALUES. LIMITS gives the limits
%   of the color scale (defualt is automatic scaling).
%
%   Frequency is plotted on a logarithmic scale. The y-tick will only
%   contain powers of 2.

if ~exist('freq','var')
  freq = [];
  elseif length(freq)~=size(values,1)
  error('Frequencies vector should have the same length as the number of rows in the values matrix.')
end

if ~exist('time','var')
  time = [];
  elseif length(time)~=size(values,2)
  error('Time vector should have the same length as the number of columns in the values matrix.')
end

if ~exist('limits','var')
  limits = [];
end

% set the axes
x = time;
y = log10(freq);

% plot
if ~isempty(limits)
  % set the scale manually
  h = imagesc(x, y, values, limits);
else
  % use the automatic scaling
  h = imagesc(x, y, values);
end

% lower frequencies at the lower part of the graph
axis xy

% x-axis
if ~isempty(time)
  xlabel('Time (ms)')
  else
  xlabel('Time')
  set(gca, 'XTick', [], 'XTickLabel', [])
end

% get the range of powers of two in the y-axis
p2 = 2.^(0:10);

% y-axis
if ~isempty(freq)
  yp2 = p2(p2>=min(freq) & p2<=max(freq));
  ylabel('Frequency (Hz)')
  else
  yp2 = [];
  ylabel('Frequency')
end

% change the y-tick to be logarithmic
set(gca, 'YTick', log10(yp2))
set(gca, 'YTickLabel', yp2)

% colorbar
c = colorbar;

% aesthetics
set(c, 'LineWidth', 2)
set(gca, 'LineWidth', 2)
if exist('publishfig')==2
  publishfig
end
