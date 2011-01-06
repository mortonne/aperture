function pat = pat_confusion(pat, stat_name, fig_name, varargin)
%PAT_CONFUSION   Create confusion matrix plots from pattern classification.
%
%  pat = pat_confusion(pat, stat_name, fig_name, ...)
%
%  INPUTS:
%        pat:  a pattern object.
%
%  stat_name:  name of the stat object containing classification
%              results.
%
%   fig_name:  string identifier for the new figure object.
%
%  OUTPUTS:
%        pat:  pat object with an added figure object.
%
%  PARAMS:
%  All fields are optional.  Default values are shown in parentheses.
%  Also see plot_erp for more plotting params.
%   class_labels     - cell array of strings giving labels for each
%                      class. ({})
%   map_limits       - [low, high] limits for the colormap. If empty,
%                      automatic limits will be used. ([])
%   print_input      - cell array of inputs to print to use when
%                      printing figures. ({'-depsc'})
%   res_dir          - path to the directory to save figures in.
%                      (get_pat_dir(pat, 'reports', 'figs'))

% options
defaults.class_labels = {};
defaults.print_input = {'-depsc'};
defaults.res_dir = get_pat_dir(pat, 'reports', 'figs');
[params, plot_params] = propval(varargin, defaults);
params.res_dir = check_dir(params.res_dir);

% load the classification results
stat = getobj(pat, 'stat', stat_name);
res = get_stat(stat, 'res');

if isfield(res, 'confmat')
  all_confmats = res.confmat;
else
  % calculate the confusion matrix
  all_confmats = class_confusion(res);
end

% get dimension info
[n_class, n_class, n_chan, n_time, n_freq] = size(all_confmats);
files = cell(1, n_chan, n_time, n_freq);
non_sing = find(size(files) > 1);
n_non_sing = length(non_sing);
dim_labels = cell(1, n_non_sing);
for i = 1:n_non_sing
  dim_labels{i} = get_dim_labels(pat.dim, non_sing(i));
end

these_labels = cell(1, n_non_sing);

colormap(hot)

for i = 1:n_chan
  for j = 1:n_time
    for k = 1:n_freq
      % plot the confusion matrix
      confmat = all_confmats(:,:,i,j,k);
      h = plot_confusion(confmat, params.class_labels, plot_params);
      
      % generate the filename
      all_ind = [1 i j k];
      non_sing_ind = all_ind(non_sing);
      for n = 1:n_non_sing
        these_labels{n} = dim_labels{n}{non_sing_ind(n)};
      end
      filename = objfilename(pat.name, fig_name, pat.source, these_labels{:});
      files{1,i,j,k} = fullfile(params.res_dir, filename);
      
      % print the figure
      print(gcf, params.print_input{:}, files{1,i,j,k});
    end
  end
end

% create a new fig object
fig = init_fig(fig_name, files, pat.name);
pat = setobj(pat, 'fig', fig);

