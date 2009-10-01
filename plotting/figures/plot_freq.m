function h = plot_freq(data, freq, params)
%PLOT_ERP   Plot an event-related potential.
%
%  h = plot_erp(data, time, params)
%
%  INPUTS:
%     data:  array of voltage values to plot. If data is a matrix, each
%            row will be plotted as a separate line.
%
%     time:  time values corresponding to each column of data.
%
%   params:  a structure specifying options for plotting. See below.
%
%  OUTPUTS:
%        h:  vector of handles for each line plotted.
%
%  PARAMS:
%   x_lim      - limits of the time axis in [min, max] form
%   time_units - units of the time axis. ('ms')
%   x_label    - label for the x-axis. ('Time (time_units)' if time
%                vector given, otherwise 'Time (samples)')
%   y_lim      - limits of the voltage axis in [min, max] form
%   volt_units - units of the voltage axis. ('\muV')
%   y_label    - label for the y-axis. ('Voltage (volt_units)')
%   colors     - cell array indicating the order of colors to use 
%                for the lines. ({})
%   mark       - boolean vector indicating samples to be marked
%                (e.g., significant samples). Shading will be put
%                just below the plot. ([])
%   fill_color - [1 X 3] array giving the color to use for marks.
%                ([.8 .8 .8])

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
