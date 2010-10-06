function pat = pat_erp(pat, fig_name, params, res_dir)
%PAT_ERP   Make event-related potential plots and print them to disk.
%
%  Create a plot for each [event X channel X frequency] in a pattern.
%  Typically used for plotting ERPs, but can also be used for plotting
%  other values that vary over time.
%
%  pat = pat_erp(pat, fig_name, params, res_dir)
%
%  INPUTS:
%           pat:  pat object containing the pattern to be plotted.
%
%      fig_name:  string identifier for the new fig object.
%
%        params:  structure with options for plotting. See below.
%
%       res_dir:  path to the directory to save figures in. If not
%                 specified, files will be saved in the pattern's
%                 reports/figs directory.
%
%  OUTPUTS:
%           pat:  pat object with an added fig object.
%
%  PARAMS:
%  All fields are optional.  Default values are shown in parentheses.
%  Also see plot_erp for more plotting params.
%   event_bins       - input to make_event_bins; can be used to average
%                      over events before plotting. ('')
%   stat_name        - name of a stat object attached to pat. If
%                      specified, p will be loaded from stat.file, and
%                      significant regions will be shaded below each
%                      plot. ('')
%   alpha            - critical value to use when determining
%                      significance. (0.05)
%   correctm         - method to use to correct for multiple
%                      comparisions. [{none} | fdr | bonferroni]
%   plot_mult_events - if true, all events will be plotted on one axis.
%                      Otherwise, each event will be plotted on a
%                      separate figure. (true)
%   print_input      - cell array of inputs to print to use when
%                      printing figures. ({'-depsc'})
%   fill_color       - color to use for shading under significant time
%                      points. ([.8 .8 .8])
%   mult_fig_windows - if true, each figure will be plotted in a
%                      separate window. (false)
%   x_lim            - if specified, x-limit for all figures will be set
%                      to this. ([])
%
%  EXAMPLES:
%   % make ERPs for each channel in my_pattern for all subjects, and
%   % save information about the plots in a fig object
%   pat_name = 'my_pattern';
%   fig_name = 'erp';
%   subj = apply_to_pat(subj, pat_name, @pat_erp, {fig_name});
%
%  See also create_pat_report, pat_topoplot.

% input checks
if ~exist('pat','var') || ~isstruct(pat)
  error('You must pass in a pat object.')
end
if ~exist('fig_name','var')
  fig_name = 'erp';
end
if ~exist('params','var')
  params = struct;
elseif ~isstruct(params)
  error('params must be a structure.')
end
if ~exist('res_dir','var') || isempty(res_dir)
  report_dir = get_pat_dir(pat, 'reports');
  cd(report_dir)
  res_dir = './figs';
elseif ~ismember(res_dir(1), {'/','.'})
  res_dir = ['./' res_dir];
end
if ~exist(res_dir,'dir');
  mkdir(res_dir)
end


% options
defaults.print_input = {'-depsc'};
defaults.event_bins = '';
defaults.plot_mult_events = true;
defaults.mult_fig_windows = false;
defaults.stat_name = '';
defaults.alpha = 0.05;
defaults.correctm = '';
[params, plot_params] = propval(params, defaults);
plot_params = propval(plot_params, struct, 'strict', false);

if ~isempty(params.event_bins)
  % apply binning (don't modify the pat object, even in the workspace)
  pattern = get_mat(bin_pattern(pat, ...
                                'eventbins', params.event_bins, ...
                                'save_mats', false));
else
  % just get the pattern
  pattern = get_mat(pat);
end

% set axis information
x = get_dim_vals(pat.dim, 'time');

if ~isempty(params.stat_name)
  % get the stat object
  stat = getobj(pat, 'stat', params.stat_name);
  
  %zach hack
  %pattern = pattern(1,:,:) - pattern(2,:,:);
  %p = getfield(load(stat.file), 'pattern');
  
  %original
  load(stat.file, 'p');
  %end zach hack
  
  
  % HACK - remove any additional p-values and take absolute value
  p = abs(p(1,:,:,:));
  % END HACK
  
  % check the size
  pat_size = patsize(pat.dim);
  stat_size = size(p);
  if any(pat_size(2:3)~=stat_size(2:3))
    error('p must be the same size as pattern.')
  end
end

% initialize a cell array to hold all the printed figures
if params.plot_mult_events
  num_events = 1;
else
  num_events = size(pattern,1);
end
files = cell(num_events, size(pattern,2), 1, size(pattern,4));
base_filename = sprintf('%s_%s_%s', pat.name, fig_name, pat.source);

num_figs = prod(size(files));
fprintf('making %d ERP plots from pattern %s...\n', num_figs, pat.name);
start_fig = gcf;

n = 1;
for i=1:num_events
  for c=1:size(pattern,2)
    for f=1:size(pattern,4)
      fprintf('%d ', n)

      if params.plot_mult_events
        e = ':';
      else
        e = i;
      end

      if params.mult_fig_windows
        figure(start_fig + n - 1)
      end
      clf

      % event-related potential(s) for this channel
      erp = squeeze(pattern(e,c,:,f));

      if ~isempty(params.stat_name)
        % get significant samples
        p_samp = squeeze(p(e,c,:,f));
        alpha_fw = correct_mult_comp(p_samp, params.alpha, params.correctm);
        %USER WARNING!
        %currently it seems this correction isn't being used! 
        %plot_params contains the mark matrix, not params...
        plot_params.mark = p_samp < alpha_fw;
      end

      % make the plot
      plot_erp(erp, x, plot_params);

      % generate the filename
      if ndims(pattern)==4
        filename = sprintf('%s_e%dc%df%d.eps', base_filename, i, c, f);
      else
        filename = sprintf('%s_e%dc%d.eps', base_filename, i, c);
      end
      files{i,c,1,f} = fullfile(res_dir, filename);

      % print this figure
      print(gcf, params.print_input{:}, files{i,c,1,f})
      n = n + 1;
    end
  end
end
fprintf('\n')

% create a new fig object
fig = init_fig(fig_name, files, pat.name);
pat = setobj(pat, 'fig', fig);
