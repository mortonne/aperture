function pat = create_broadband_corr_pattern(pat, stat_name, varargin)
%CREATE_BROADBAND_CORR_PATTERN Create a power pattern with broadband
%  power removed, based on the broadband regression estimates.
%  Requires as an input the stat object created by
%  broadband_regression.
%
%  pat = create_broadband_corr_pattern(pat, stat_name, bb_pat_name, ...)
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
%      pat:  the pattern of power estimates with broadband removed.
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
%  fragment_path   - if fragmenting the variables, where to save
%                    the temporary files
%  fragment_dim    - dimension along which to do the fragmenting
%

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must input a pattern object.')
end

% options
defaults.plot = false;
defaults.stat_var_name = 'b';
defaults.fragment_path = '';
defaults.fragment_dim = 1;
[params, saveopts] = propval(varargin, defaults);

pat = mod_pattern(pat, @apply_bb_removal, {stat_name, params}, saveopts); 

function pat = apply_bb_removal(pat, stat_name, params)
%
% params.fragment_path = '/data7/scratch/polyn/analysis/iCatFR/patterns/temp_fragments';
% params.fragment_dim = 2;


% load the pattern
% pattern = get_mat(pat);

% frequency information
freqs = get_dim_vals(pat.dim, 'freq');
log_freqs = log2(freqs);

d1 = length(get_dim_vals(pat.dim,1));
d2 = length(get_dim_vals(pat.dim,2));
d3 = length(get_dim_vals(pat.dim,3));
d4 = length(get_dim_vals(pat.dim,4));

% fragment the pattern
pat_cell = fragment_variable(pat.file, 'pattern', ...
                             params.fragment_path, ...
                             params.fragment_dim, ...
                             pat.source);

% grab the stat with the bb coefficients
stat = getobj(pat, 'stat', stat_name);
% load the bb coefficients matrix
% b = get_stat(stat, params.stat_var_name);

% fragment the coefficients
b_cell = fragment_variable(stat.file, 'b', ...
                           params.fragment_path, ...
                           params.fragment_dim, ...
                           pat.source);

if length(pat_cell) ~= length(b_cell)
  error('cell arrays must be of equal length');
end

pattern = zeros(d1,d2,d3,d4,'single');
place = {':',':',':',':'};

for i=1:length(pat_cell)
  
  pat_frag = load(pat_cell{i}, 'frag');
  b_frag = load(b_cell{i}, 'frag');
  
  bbcorr_frag = bb_removal(pat_frag.('frag'), b_frag.('frag'), log_freqs);
  
  place{params.fragment_dim} = i;
  pattern(place{:}) = bbcorr_frag;
  
end

% initialize the pat object
pat = set_mat(pat, pattern, 'ws');


function corr_pattern = bb_removal(pattern, b, log_freqs)
%

[d1,d2,d3,d4] = size(pattern);
corr_pattern = zeros(size(pattern),'single');

% create the bb corrected pattern
for i=1:d1
  for j=1:d2
    for k=1:d3
      corr_pattern(i,j,k,:) = squeeze(pattern(i,j,k,:))' ...
          - (b(i,j,k,1) + log_freqs .* b(i,j,k,2));
    end
  end
end
% endfunction


