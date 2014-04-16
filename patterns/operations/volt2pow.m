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

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

% options
defaults.width = 6;
defaults.buffer = [];
defaults.logtransform = true;
defaults.downsample = [];
defaults.split = true;
defaults.precision = '';
defaults.verbose = true;
defaults.dist = false;
[params, saveopts] = propval(varargin, defaults);

% make the new pattern
pat = mod_pattern(pat, @get_pow_pat, {freqs, params}, saveopts);


function pat = get_pow_pat(pat, freqs, params)

% load the full pattern and then save out each channel separately
if (params.split || params.dist) && ~isfield(pat.dim, 'splitdim')
  pat_file = pat.file;
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

if ~params.dist
  pow_pattern = NaN(n_events, n_chans, n_samps, n_freqs, precision);
else
  run_opt.memory = '4G';
  run_opt.walltime = '02:00:00';
  sm = getScheduler();
  sm = setQsub(sm, run_opt);

  % create the job
  main_dir = fileparts(which('accre'));
  job_startup_file = fullfile(main_dir, 'jobStartup.m');
  job = createJob(sm, 'AttachedFiles', {job_startup_file});
  job.Name = mfilename;
end
  
% calculate power
if params.verbose
  if params.dist
    fprintf('Creating tasks...\n')
  else
    fprintf('calculating power...\n')
  end
end

chan_labels = get_dim_labels(pat.dim, 'chan');
for i = 1:n_chans
  if params.verbose
    fprintf('%s ', chan_labels{i})
  end
  
  if ~params.dist
    if isfield(pat.dim, 'splitdim')
      load(pat.file{i});
      eeg = permute(pattern, [1 3 2]);
    else
      eeg = permute(pattern(:,i,:), [1 3 2]);
    end
    
    power = calc_power(freqs, eeg, samplerate, precision, ...
                       buffer, dmate, params);
    pow_pattern(:,i,:,:) = permute(power, [1 3 2]);
  else
    createTask(job, @calc_power, 1, {freqs, pat.file{i}, samplerate, ...
               precision, buffer, dmate, params});
  end
end
if params.verbose
  fprintf('\n')
end

if params.dist
  clear pattern eeg

  fprintf('Submitting job...\n')
  submit(job)
  
  fprintf('Job submitted. Waiting for job to finish...\n')
  wait(job)

  o = fetchOutputs(job);
  pow_pattern = NaN(n_events, n_chans, n_samps, n_freqs, precision);
  for i = 1:length(o)
    pow_pattern(:,i,:,:) = permute(o{i}, [1 3 2]);
  end
end

% set the matrix
pat = set_mat(pat, pow_pattern, 'ws');
pat.dim = set_dim(pat.dim, 'freq', init_freq(freqs), 'ws');
if params.split
  pat.dim = rmfield(pat.dim, 'splitdim');
  %pat.file = pat_file;
  pat.file = pat.orig_file;
  pat = rmfield(pat, 'orig_file');
end

% remove the buffer from the time dim
if ~isempty(buffer)
  time = get_dim(pat.dim, 'time');
  pat.dim = set_dim(pat.dim, 'time', time(buffer+1:end-buffer), 'ws');
end

% correct for downsampling
if ~isempty(params.downsample)
  ms = get_dim_vals(pat.dim, 'time');
  start = ms(1);
  new_step_size = fix(1000 / params.downsample);
  finish = ms(end);
  time = init_time(start:new_step_size:finish);
  pat.dim = set_dim(pat.dim, 'time', time, 'ws');
end


function y = decimate_power(x, factor)

  n_samps = ceil(size(x, 3) / factor);
  y = NaN(size(x, 1), size(x, 2), n_samps);
  
  % must log transform power before decimating
  x(x == 0) = eps(0);
  x = log10(x);
  for i = 1:size(x, 1)
    for j = 1:size(x, 2)
      time = permute(x(i,j,:), [1 3 2]);
      time = decimate(double(time), factor);
      y(i,j,:) = time;
    end
  end
  
  % convert back to original scale
  y = 10.^y;

function power = calc_power(freqs, eeg, samplerate, precision, ...
                            buffer, dmate, params)
  
  if ischar(eeg)
    eeg = getfield(load(eeg, 'pattern'), 'pattern');
    eeg = permute(eeg, [1 3 2]);
  end
  
  [~, power] = multiphasevec3(freqs, eeg, samplerate, ...
                              params.width, precision);
  
  % remove the buffer
  if ~isempty(buffer)
    power = power(:,:,buffer+1:end-buffer);
  end

  % downsample the power values
  if ~isempty(params.downsample)
    power = decimate_power(power, dmate);
  end
    
  % log transform
  if params.logtransform
    power(power == 0) = eps(0);
    power = log10(power);
  end
