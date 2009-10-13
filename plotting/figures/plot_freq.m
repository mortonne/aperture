function h = plot_freq(data, freq, params)
%PLOT_FREQ   Plot a variable versus frequency.
%
%  h = plot_freq(data, freq, params)
%
%  INPUTS:
%     data:  array of voltage values to plot. If data is a matrix, each
%            row will be plotted as a separate line.
%
%     freq:  frequency values corresponding to each column of data.
%
%   params:  a structure specifying options for plotting. See below.
%
%  OUTPUTS:
%        h:  vector of handles for each line plotted.
%
%  PARAMS:
%   x_lim      - limits of the time axis in [min, max] form
%   freq_units - units of the frequency axis. ('Hz')
%   x_label    - label for the x-axis. ('Frequency (freq_units)' if
%                frequency vector given, otherwise 'Frequency (samples)')
%   y_lim      - limits of the y axis in [min, max] form
%   y_label    - label for the y-axis. ('')
%   colors     - cell array indicating the order of colors to use 
%                for the lines. ({})
%   plot_fcn   - function used for plotting (@plot, unless err_type is
%                specified; then @errorbar)
%   plot_input - cell array of optional inputs to plot_fcn
%   err_type   - type of error to use for plotting error bars. [{'std'}]

% input checks
if ~exist('data','var')
  error('You must pass a matrix of values to plot.')
end
if ~exist('freq','var')
  freq = [];
end
if ~exist('params','var')
  params = [];
end

% set default parameters
params = structDefaults(params, ...
                        'freq_units',       'Hz',       ...
                        'colors',           {},         ...
                        'x_lim',            [],         ...
                        'y_lim',            [],         ...
                        'x_label',          '',         ...
                        'y_label',          '',         ...
                        'x_tick',           [],         ...
                        'plot_fcn',         @errorbar,  ...
                        'plot_input',       {},         ...
                        'mark',             [],         ...
                        'err_type',         '');

clf

switch params.err_type
 case 'std'
  err = std(data)/sqrt(size(data,1)-1);
  data = mean(data);
end

% x-axis values
if ~isempty(freq)
  x = log(freq);
else
  x = 1:size(data,2);
end

% set the x-limits
if ~isempty(params.x_lim)
  x_lim = params.x_lim;
else
  x_lim = [x(1) x(end)];
end

% min and max of the data
y_min = min(data(:));
if isnan(y_min)
  y_min = -1;
end
y_max = max(data(:));
if isnan(y_max)
  y_max = 1;
end

% set the y-limits
if ~isempty(params.y_lim)
  % use standard y-limits
  y_lim = params.y_lim;
else
  % buffer from top and bottom
  buffer = (y_max-y_min)*0.2;
  y_lim = [y_min-buffer y_max+buffer];
end

% make the plot
if isempty(params.err_type)
  h = plot(x, data, params.plot_input{:}, 'LineWidth', 2);
else
  h = errorbar(x, data, err, params.plot_input{:}, 'LineWidth', 2);
end

if ~isempty(params.mark)
  if ~isvector(data)
    error('Cannot plot marks when there are multiple lines to plot.')
  elseif length(params.mark) ~= length(data)
    error('mark must be the same length as data.')
  end
  
  hold on
  plot(x, data(params.mark), 'or', 'MarkerFaceColor', 'r');
end

publishfig

% change line colors from their defaults
if ~isempty(params.colors)
  for i=1:length(h)
    set(h(i), 'Color', params.colors{mod(i-1,length(params.colors))+1})
  end
end

% set limits
set(gca, 'YLim',y_lim)

% get the range of powers of two in the y-axis
p2 = 2.^(0:10);

if ~isempty(freq)
  inds = p2>=min(freq) & p2<=max(freq);
  xp2 = p2(inds);
  xlabel(sprintf('Frequency (%s)', params.freq_units))
else
  xp2 = [];
  xlabel('Frequency')
end

set(gca, 'XTick', log(xp2), 'XTickLabel', xp2)

% x-axis label
if ~isempty(params.x_label)
  xlabel(params.x_label)
elseif ~isempty(freq)
  xlabel(sprintf('Frequency (%s)', params.freq_units))
else
  xlabel('Frequency Number')
end

% y-axis
if ~isempty(params.y_label)
  ylabel(params.y_label)
end
