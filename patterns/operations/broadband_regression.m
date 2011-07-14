function pat = broadband_regression(pat, stat_name, varargin)
%BROADBAND_REGRESSION   Calculate broadband power using robust regression.
%
%  pat = broadband_regression(pat, stat_name, ...)
%
%  INPUTS:
%      pat:  input pattern object containing log-transformed power
%            values.
%
%  OUTPUTS:
%      pat:  the original pattern with a stat object attached with a
%            matrix named "b" that contains regression coefficients.
%            b(i,j,k,1) and b(i,j,k,2) give the intercept and slope,
%            respectively, of event i, channel j, time k.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   plot - if true, each regression will be plotted. (false);

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must input a pattern object.')
end

% options
defaults.plot = false;
[params, saveopts] = propval(varargin, defaults);

% load the pattern
pattern = get_mat(pat);

% frequency information
[n_events, n_chans, n_time, n_freq] = size(pattern);
freqs = get_dim_vals(pat.dim, 'freq');

iter_warn = 'stats:statrobustfit:IterationLimit';
state = warning('query', iter_warn);
warning('off', iter_warn);
n_step = 100;
step = floor((n_events * n_chans * n_time) / n_step);
n = 0;

b = NaN(n_events, n_chans, n_time, 2, class(pattern));
pow = NaN(1, n_freq);
log_freqs = log2(freqs);
for i = 1:n_events
  for j = 1:n_chans
    for k = 1:n_time
      n = n + 1;
      if mod(n, step) == 0
        fprintf('.')
      end
      
      pow = permute(pattern(i,j,k,:), [1 4 2 3]);
      if all(isnan(pow))
        continue
      end
      
      % fit power on frequency
      b(i,j,k,:) = robustfit(log_freqs, pow);
      
      if params.plot
        clf
        plot_freq(b(i,j,k,1) + log_freqs * b(i,j,k,2), freqs);
        hold on
        plot_freq(pow, freqs, struct('y_label', 'Power'));
        drawnow
        pause(.5)
      end
      
    end
  end
end
fprintf('\n');
warning(state.state, iter_warn);

% initialize the stat object
stat_file = fullfile(get_pat_dir(pat, 'stats'), ...
                     objfilename('stat', stat_name, pat.source));

stat = init_stat(stat_name, stat_file, pat.source, params);
save(stat.file, 'b', 'stat');
pat = setobj(pat, 'stat', stat);

