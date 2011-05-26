function h = plot_tfr(data, freq, time, params)
%PLOT_TFR   Make a spectrogram from a time-frequency representation.
%
%  h = plot_tfr(data, freq, time, params)
%
%  Frequency is plotted on a logarithmic scale. The y-tick will only
%  contain powers of 2.
%
%  INPUTS:
%     data:  [frequency X time] matrix of data to be plotted.  
%
%     freq:  vector giving frequency for each row of data.
%
%     time:  vector giving time for each column of data.
%
%   params:  structure specifying options for plotting. See below.
%
%  OUTPUTS:
%        h:  handle to the image.
%
%  PARAMS:
%   freq_units - units of the frequency axis ('Hz')
%   time_units - units of the time axis ('ms')
%   map_limits - limits for the z-axis ([])
%   colorbar   - boolean; if true, a colorbar will be displayed (true)
%   colormap   - colormap to use for mapping z-values to colors ([])

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

% input checks
if ~exist('data', 'var')
  error('You must pass a matrix of values to plot.')
end
if ~exist('freq', 'var')
  freq = [];
elseif length(freq)~=size(data,1)
  error('Frequencies vector should have the same length as the number of rows in the data matrix.')
end
if ~exist('time', 'var')
  time = [];
elseif length(time)~=size(data,2)
  error(['Time vector should have the same length as the number of ' ...
         'columns in the data matrix.'])
end
if ~exist('params', 'var')
  params = [];
end

% set default parameters
params = structDefaults(params, ...
                        'freq_units', 'Hz',  ...
                        'time_units', 'ms',  ...
                        'ms2s',       false, ...
                        'map_limits',   [],    ...
                        'colorbar',   true, ...
                        'colormap',   []);

% set the axes
if params.ms2s
  time = time / 1000;
end

x = time;
y = log10(freq);

% plot
if ~isempty(params.map_limits)
  % set the scale manually
  h = imagesc(x, y, data, params.map_limits);
else
  % use the automatic scaling
  h = imagesc(x, y, data);
end

% lower frequencies at the lower part of the graph
axis xy

% x-axis
if ~isempty(time)
  xlabel(sprintf('Time (%s)', params.time_units))
else
  xlabel('Time')
  set(gca, 'XTick', [], 'XTickLabel', [])
end

% get the range of powers of two in the y-axis
p2 = 2.^(0:10);

% y-axis
if ~isempty(freq)
  yp2 = p2(p2>=min(freq) & p2<=max(freq));
  ylabel(sprintf('Frequency (%s)', params.freq_units))
else
  yp2 = [];
  ylabel('Frequency')
end
publishfig

% change the y-tick to be logarithmic
set(gca, 'YTick', log10(yp2))
set(gca, 'YTickLabel', yp2)

set(gca, 'LineWidth', 2)

% colorbar
if params.colorbar
  c = colorbar;
  set(c, 'LineWidth', 2)
end
if ~isempty(params.colormap)
  colormap(params.colormap);
end


