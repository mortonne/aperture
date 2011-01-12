function subj = create_voltage_pattern(subj, pat_name, params, res_dir)
%CREATE_VOLTAGE_PATTERN   Create a voltage pattern for one subject.
%
%  subj = create_voltage_pattern(subj, pat_name, params, res_dir)
%
%  INPUTS:
%      subj:  subject object. See get_sessdirs.
%
%  pat_name:  string identifier for the pattern.
%
%    params:  structure that specifies options for pattern creation. See
%             below for options.
%
%   res_dir:  path to the directory to save results. patterns will be
%             saved in [res_dir]/patterns; if events are modified, new
%             events will be saved in [res_dir]/events.
%
%  OUTPUTS:
%      subj:  modified subject object, with a pattern object named
%             pat_name added.
%
%  PARAMS:
%  Defaults are shown in parentheses.
%   evname          - REQUIRED - name of the events object to use.
%   replace_eegfile - [N X 2] cell array, where each row contains two
%                     strings to be passed into strrep, to change the
%                     eegfile field in events. ({})
%   eventFilter     - input to filterStruct which designates which
%                     events to include in the pattern. ('')
%   chanFilter      - used to choose which channels to include in the
%                     pattern. Can be a string to pass into
%                     filterStruct, an array of channel numbers to
%                     include, or a cell array of channel labels to
%                     include. ('')
%   offsetMS        - time in milliseconds before each event to start
%                     the pattern. (-200)
%   durationMS      - duration in milliseconds of each epoch. (2200)
%   relativeMS      - range of times relative to the start of each event
%                     to use for baseline correction. ([-200 0])
%   resampledRate   - samplerate (in Hz) to resample to. ([])
%   filttype        - type of filter to use (see buttfilt). ('low')
%   filtfreq        - frequency range for filter (see buttfilt). (40)
%   filtorder       - order of filter (see buttfilt). (4)
%   bufferMS        - size of buffer to use when filtering (see buttfilt)
%                     (1000)
%   precision       - precision of the returned values. ('double')
%   overwrite       - if true, existing pattern files will be
%                     overwritten (false)
%   updateOnly      - if true, the pattern will not be created, but a
%                     pattern object will be created and attached to the
%                     subject object. (false)
%   verbose         - if true, more status will be printed. (false)
%
%  See also create_power_pattern.

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
end
if ~exist('params', 'var')
  params = struct;
elseif ~isstruct(params)
  error('params must be a structure.')
end
if ~exist('pat_name', 'var')
  pat_name = 'voltage';
elseif ~ischar(pat_name)
  error('pat_name must be a string.')
end
if ~exist('res_dir', 'var')
  error('You must specify a path to a directory in which to save results.')
elseif ~ischar(res_dir)
  error('res_dir must be a string.')
end

% create_pattern and voltage_pattern will set the default params
subj = create_pattern(subj, @voltage_pattern, params, pat_name, res_dir);

