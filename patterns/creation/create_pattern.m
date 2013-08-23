function subj = create_pattern(subj, fcn_handle, params, pat_name, res_dir)
%CREATE_PATTERN   Create a pattern for a subject.
%
%  subj = create_pattern(subj, fcn_handle, params, pat_name, res_dir)
%
%  INPUTS:
%        subj:  subject object. See get_sessdirs.
%
%  fcn_handle:  handle to a function that returns an
%               [events X channels X time (X frequency)] matrix for one
%               session. Must be of the form:
%                [pattern, params] = fcn_handle(events, channels, ...
%                                     params, base_events, bins)
%               See sessVoltage and sessPower for examples of compatible
%               functions.
%
%      params:  structure that specifies options for pattern creation.
%               See below.  params will also be passed to fcn_handle.
%
%    pat_name:  string identifier for the pattern.
%
%     res_dir:  path to the directory to save results. patterns will be
%               saved in [res_dir]/patterns; if events are modified,
%               new events will be saved in [res_dir]/events.
%
%  OUTPUTS:
%        subj:  modified subject object, with a "pat" object named
%               pat_name added.
%
%  PARAMS:
%  All fields are optional. Defaults are shown in parentheses.
%   evname          - name of the events object to use. If empty, the
%                     last events added will be used. ('')
%   replace_eegfile - [N X 2] cell array, where each row contains two
%                     strings to be passed into strrep, to change the
%                     eegfile field in events. ({})
%   eventFilter     - input to filterStruct which designates which
%                     events to include in the pattern. ('')
%   chanFilter      - used to choose which channels to include in the
%                     pattern. Can be a string to pass into
%                     filterStruct, or an array of channel numbers to
%                     include. ('')
%   offsetMS        - time in milliseconds before each event to start
%                     the pattern. (-200)
%   durationMS      - duration in milliseconds of each epoch. (2200)
%   resampledRate   - samplerate (in Hz) to resample to. ([])
%   downsample      - samplerate (in Hz) to downsample oscillatory
%                     power. ([])
%   freqs           - for patterns with a frequency dimension, specifies
%                     which frequencies (in Hz) the pattern should 
%                     include ([])
%   precision       - precision of the returned values.
%                     ['single' | {'double'}]
%   overwrite       - if true, existing pattern files will be
%                     overwritten (false)
%
%  See also create_voltage_pattern, create_power_pattern.

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

% input checks
if ~exist('subj', 'var') || ~isstruct(subj)
  error('You must pass a subject object.')
elseif length(subj) > 1
  error('You must pass only one subject.')
elseif ~all(isfield(subj, {'id', 'chan', 'ev'}))
  error('The subject object must have "id", "chan", and "ev" fields.')
elseif ~exist('fcn_handle', 'var') || ~isa(fcn_handle, 'function_handle')
  error('You must pass a function handle.')
end
if ~exist('params', 'var')
  params = struct;
end
if ~exist('pat_name', 'var')
  pat_name = 'pattern';
elseif ~ischar(pat_name)
  error('pat_name must be a string.')
end
if ~exist('res_dir', 'var')
  error('You give a path to a directory in which to save results.')
elseif ~ischar(res_dir)
  error('res_dir must be a string.')
end

% default parameters
defaults.evname = '';
defaults.replace_eegfile = {};
defaults.eventFilter = '';
defaults.chanFilter = '';
defaults.offsetMS = -200;
defaults.durationMS = 2200;
defaults.resampledRate = [];
defaults.downsample = [];
defaults.freqs = [];
defaults.precision = 'double';
defaults.overwrite = false;
params = propval(params, defaults, 'strict', false);

% print status
if ~params.updateOnly
  fprintf('creating "%s" pattern from "%s" events using %s...\n', ...
          pat_name, params.evname, func2str(fcn_handle))
end

% set where the pattern will be saved
pat_dir = fullfile(res_dir, 'patterns');
pat_file = fullfile(pat_dir, ...
                    [objfilename('pattern', pat_name, subj.id) '.mat']);

if ~params.overwrite && exist(pat_file, 'file')
  fprintf('pattern exists in %s.\nskipping...\n', pat_file)
  return
end
if ~exist(res_dir, 'dir')
  mkdir(res_dir);
end
if ~exist(pat_dir, 'dir')
  mkdir(pat_dir)
end

% events dimension
ev = getobj(subj, 'ev', params.evname);
ev = move_obj_to_workspace(ev);

% fix the EEG file field if needed
if ~isempty(params.replace_eegfile)
  temp = params.replace_eegfile';
  ev.mat = rep_eegfile(ev.mat, temp{:});
  ev.modified = true;
end

% get channel info from the subject
chan = get_dim(subj, 'chan');

% time dimension
if ~isempty(params.downsample)
  step_size = 1000 / params.downsample;
else
  if isempty(params.resampledRate)
    % if not resampling, we'll need to know the samplerate of the data
    % so we can initialize the pattern.
    samplerates = unique(get_events_samplerate(ev.mat));
    if length(samplerates) > 1
      params.resampledRate = min(samplerates);
      fprintf(['events contain multiple samplerates. ' ...
               'Resampling to %.f Hz...\n'], params.resampledRate)
    else
      params.resampledRate = samplerates(1);
    end
  end
  step_size = 1000 / params.resampledRate;
end

% millisecond values for the final pattern
end_ms = params.offsetMS + params.durationMS;
ms_values = params.offsetMS:step_size:end_ms;

% greater limit is non-inclusive
if ms_values(end) == end_ms
  ms_values(end) = [];
end
time = init_time(ms_values);

% frequency dimension
freq = init_freq(params.freqs);

% create a pat object to keep track of this pattern
pat = init_pat(pat_name, pat_file, subj.id, params, ...
               ev.mat, chan, time, freq);

% filter events and channels
try
  pat = patFilt(pat, params);
catch err
  id = get_error_id(err);
  if strcmp(id, 'EmptyPattern')
    error('Filtering will remove a dimension of the pattern.')
  else
    rethrow(err)
  end
end

% get filtered events and channels for pattern creation
events = get_mat(pat.dim.ev);
channels = get_dim_vals(pat.dim, 'chan');

% create the pattern
[pattern, total_params] = fcn_handle(events, channels, params);
pat.params = combineStructs(params, total_params);

% save the pattern
pat = set_mat(pat, pattern, 'hd');
fprintf('pattern saved in %s.\n', pat.file)

% save dimension information to disk
pat = upgrade_pattern(pat);

% update subj with the new pat object
subj = setobj(subj, 'pat', pat);

