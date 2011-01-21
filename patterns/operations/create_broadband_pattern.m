function pat = create_broadband_pattern(pat, stat_name, varargin)
%CREATE_BROADBAND_PATTERN   Create a broadband power pattern based on
%  the broadband regression estimates.  Requires as an input the
%  stat object created by broadband_regression.
%
%  pat = create_broadband_pattern(pat, stat_name, bb_pat_name, ...)
%
%  INPUTS:
%      pat:  input pattern object containing log-transformed power
%            values.
%
%  stat_name:  the name of the statistic containing your broadband
%              coefficients
%
%
%  OUTPUTS:
%      pat:  the pattern of broadband power estimates.
%
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
%  stat_var_name   - the name of the variable containing your
%                    broadband coefficients (in the file on the
%                    stat object). ('b')
%

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must input a pattern object.')
end

% options
defaults.plot = false;
defaults.stat_var_name = 'b';
[params, saveopts] = propval(varargin, defaults);

pat = mod_pattern(pat, @apply_bb_creation, {stat_name, params}, saveopts); 

function pat = apply_bb_creation(pat, stat_name, params)

% load the pattern
pattern = get_mat(pat);

% grab the stat with the bb coefficients
stat = getobj(pat, 'stat', stat_name);

% load the bb coefficients matrix
b = get_stat(stat, params.stat_var_name);

% frequency information
% [n_events, n_chans, n_time, n_freq] = size(pattern);
freqs = get_dim_vals(pat.dim, 'freq');

% create the bb power matrix
bb_pattern = b(:,:,:,1) + (log2(mean(freqs)) .* b(:,:,:,2));

% initialize the pat object
pat = set_mat(pat, bb_pattern, 'ws');

% update the dims struct
pat.dim = set_dim(pat.dim, 'freq', init_freq());


