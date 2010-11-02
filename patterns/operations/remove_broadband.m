function pat = remove_broadband(pat, varargin)
%REMOVE_BROADBAND   Subtract broadband power from a pattern.
%
%  pat = remove_broadband(pat, ...)
%
%  INPUTS:
%      pat:  input pattern object containing log-transformed power
%            values.
%
%  OUTPUTS:
%      pat:  pattern with broadband power subtracted.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   save_mats      - if true, and input mats are saved on disk, modified
%                    mats will be saved to disk. If false, the modified
%                    mats will be stored in the workspace, and can
%                    subsequently be moved to disk using move_obj_to_hd.
%                    (true)
%   overwrite      - if true, existing patterns on disk will be
%                    overwritten. (false)
%   save_as        - string identifier to name the modified pattern. If
%                    empty, the name will not change. ('')
%   res_dir        - directory in which to save the modified pattern and
%                    events, if applicable. Default is a directory named
%                    pat_name on the same level as the input pat.

% original procedure (from getbroad in eeg_toolbox trunk):
% get average over freq indices (not the freqs themselves)
% robustfit power on freq index (power may be pooled over whole event or
%   be just at a single timepoint)
% broadband is power at mean freq index (using the index really
%   seems strange)

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must input a pattern object.')
end

% options
defaults.plot = false;
[params, saveopts] = propval(varargin, defaults);

% run broadband subtraction
pat = mod_pattern(pat, @run_remove_broadband, {params}, saveopts);

function pat = run_remove_broadband(pat, params)
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
  b = NaN(1, 2);
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
        b = robustfit(log_freqs, pow);
      
        % if params.plot
        %   clf
        %   subplot(2,1,1)
        %   plot_freq(b(1) + log_freqs * b(2), freqs);
        %   hold on
        %   plot_freq(pow, freqs, struct('y_label', 'Power'));
        
        %   subplot(2,1,2)
        %   plot_freq(pow - (b(1) + log_freqs * b(2)), freqs, struct('y_label', 'Power'));
        % end
      
        % get the residuals from the robust fit
        pattern(i,j,k,:) = pow - (b(1) + log_freqs * b(2));
      end
    end
  end
  fprintf('\n');
  warning(state.state, iter_warn);
  
  pat = set_mat(pat, pattern, 'ws');

