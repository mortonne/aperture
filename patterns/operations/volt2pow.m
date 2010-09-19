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
%   buffer     - time in milliseconds to strip from both sides of each
%                epoch. Useful if you have used a buffer to prevent edge
%                artifacts in the power calculation. ([])
%   downsample - rate in hertz at which to sample the calculated power
%                values in the returned pattern. Default is the same as
%                the samplerate of the voltage. ([])
%   split      - if true, the voltage pattern be loaded by channel to
%                conserve memory (this takes extra time). (true)
%   precision  - the precision of the returned power values. Default is
%                the same precision as the voltage pattern. ('')
%   save_mats  - if true, and input mats are saved on disk, modified
%                mats will be saved to disk. If false, the modified mats
%                will be stored in the workspace, and can subsequently
%                be moved to disk using move_obj_to_hd. (true)
%   overwrite  - if true, existing patterns on disk will be overwritten.
%                (false)
%   save_as    - string identifier to name the modified pattern. If
%                empty, the name will not change. ('')
%   res_dir    - directory in which to save the modified pattern and
%                events, if applicable. Default is a directory named
%                pat_name on the same level as the input pat.

defaults.width = 6;
defaults.buffer = [];
defaults.downsample = [];
defaults.split = true;
defaults.precision = '';
[params, saveopts] = propval(varargin, defaults);

% make the new pattern
pat = mod_pattern(pat, @get_pow_pat, {freqs, params}, saveopts);


function pat = get_pow_pat(pat, freqs, params)

% load the full pattern and then save out each channel separately
if params.split && ~isfield(pat, 'splitdim')
  pat = split_pattern(pat, 'chan');
elseif ~isfield(pat, 'splitdim')
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
  dmate = round(samplerate / params.downsample);
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
for i = 1:n_chans
  if isfield(pat, 'splitdim')
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

pat = set_mat(pat, pow_pattern, 'ws');

