function pat = volt2pow(pat, freqs, varargin)
%VOLT2POW   Calculate power from a voltage pattern.
%
%  pat = volt2pow(pat, freqs, ...)
%
%  INPUTS:
%      pat:  a pattern object containing voltage values.
%
%    freqs:  vector of frequencies at which power will be calculated.
%
%  OUTPUTS:
%      pat:  power pattern object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   buffer       - time in milliseconds to strip from both sides of each
%                  epoch. Useful if you have used a buffer to prevent
%                  edge artifacts in the power calculation. ([])
%   logtransform - if true, power will be log-transformed. (true)
%   downsample   - rate in hertz at which to sample the calculated power
%                  values in the returned pattern. Default is the same as
%                  the samplerate of the voltage. ([])
%   split        - if true, the voltage pattern be loaded by channel to
%                  conserve memory (this takes extra time). (true)
%   precision    - the precision of the returned power values. Default
%                  is the same precision as the voltage pattern. ('')
%   verbose      - if true, status messages will be printed. (true)
%   save_mats    - if true, and input mats are saved on disk, modified
%                  mats will be saved to disk. If false, the modified
%                  mats will be stored in the workspace, and can
%                  subsequently be moved to disk using move_obj_to_hd.
%                  (true)
%   overwrite    - if true, existing patterns on disk will be
%                  overwritten. (false)
%   save_as      - string identifier to name the modified pattern. If
%                  empty, the name will not change. ('')
%   res_dir      - directory in which to save the modified pattern and
%                  events, if applicable. Default is a directory named
%                  pat_name on the same level as the input pat.

% options
defaults.width = 6;
defaults.buffer = [];
defaults.logtransform = true;
defaults.downsample = [];
defaults.split = true;
defaults.precision = '';
defaults.verbose = true;
[params, saveopts] = propval(varargin, defaults);

% make the new pattern
pat = mod_pattern(pat, @get_pow_pat, {freqs, params}, saveopts);


function pat = get_pow_pat(pat, freqs, params)

% load the full pattern and then save out each channel separately
if params.split && ~isfield(pat.dim, 'splitdim')
  pat = split_pattern(pat, 'chan');
elseif ~isfield(pat.dim, 'splitdim')
  pattern = get_mat(pat);
end

% samples after removing buffer
samplerate = get_pat_samplerate(pat);
if ~isempty(params.buffer)
  buffer = ms2samp(params.buffer, samplerate);
  n_samps = patsize(pat.dim, 3) - 2 * buffer;
else
  buffer = [];
  n_samps = patsize(pat.dim, 3);
end

% samples after decimation
if ~isempty(params.downsample)
  dmate = samplerate / params.downsample;
  if mod(dmate, 1) ~= 0
    error('downsample must divide evenly into samplerate.')
  end
  n_samps = ceil(n_samps / dmate);
end

% initialize the new pattern
n_events = patsize(pat.dim, 1);
n_chans = patsize(pat.dim, 2);
if ~isempty(params.precision)
  precision = params.precision;
elseif exist('pattern', 'var')
  precision = class(pattern);
else
  load(pat.file{1});
  precision = class(pattern);
end
n_freqs = length(freqs);
pow_pattern = NaN(n_events, n_chans, n_samps, n_freqs, precision);

% calculate power
if params.verbose
  fprintf('calculating power...\n')
end

chan_labels = get_dim_labels(pat.dim, 'chan');
for i = 1:n_chans
  if params.verbose
    fprintf('%s ', chan_labels{i})
  end
  
  if isfield(pat.dim, 'splitdim')
    load(pat.file{i});
    c = 1;
  else
    c = i;
  end
  
  for j = 1:n_events
    % EEG as [1 X time]
    eeg = permute(pattern(j,c,:), [1 3 2]);
    [phase, power] = multiphasevec2(freqs, eeg, samplerate, params.width);
    
    % remove the buffer
    if ~isempty(buffer)
      power = power(:, buffer+1:end-buffer);
    end
    
    if params.logtransform
      % if any values are exactly 0, make them eps
      power(power==0) = eps(0);
      power = log10(power);
    end
    
    % downsample
    if ~isempty(params.downsample)
      temp = NaN(n_freqs, n_samps);
      for k = 1:n_freqs
        temp(k,:) = decimate(double(power(k,:)), dmate);
      end
      if strcmp(params.precision, 'single')
        temp = single(temp);
      end
      power = temp;
    end
    pow_pattern(j,c,:,:) = power';
  end
end
if params.verbose
  fprintf('\n')
end

pat = set_mat(pat, pow_pattern, 'ws');
pat.dim = set_dim(pat.dim, 'freq', init_freq(freqs));

% remove the buffer from the time dim
if ~isempty(buffer)
  time = get_dim(pat.dim, 'time');
  pat.dim = set_dim(pat.dim, 'time', time(buffer+1:end-buffer));
end

% correct for downsampling
if ~isempty(params.downsample)
  ms = get_dim_vals(pat.dim, 'time');
  start = ms(1);
  new_step_size = fix(1000 / params.downsample);
  finish = ms(end);
  time = init_time(start:new_step_size:finish);
  pat.dim = set_dim(pat.dim, 'time', time);
end

