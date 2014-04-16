function h = plot_erp_image(data, time, index, varargin)
%PLOT_ERP_IMAGE   Plot an ERP image and ERP.
%
%  h = plot_erp_image(data, time, index, ...)

% options
def.plot_index = [];
def.map_limits = [];
def.prc_limit = 90;
opt = propval(varargin, def);

if isempty(opt.map_limits)
  abs_prc = prctile(abs(data(:)), opt.prc_limit);
  opt.map_limits = [-abs_prc abs_prc];
end

if nargin < 3 || isempty(index)
  index = [];
  opt.plot_index = false;
end

if nargin < 2 || isempty(time)
  time = 1:size(data, 2);
end

clf
hold on

subplot('position', [0.175 0.275 0.75 0.65]);
h = image_sorted(data, time, index, ...
                 'map_limits', opt.map_limits, ...
                 'plot_index', opt.plot_index);
xlabel(gca, '');
set(gca, 'XTickLabel', '');

% plot the average
pos = get(gca, 'Position');
subplot('position', [pos(1) 0.15 pos(3) 0.1]);
plot_erp(nanmean(data, 1), time, 'plot_zero', false, ...
         'plot_input', {'LineWidth', 1});
ylabel('V (\muV)')
drawnow
hold off

