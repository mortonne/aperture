function subj = create_voltage_pattern(subj, pat_name, params, res_dir)
%CREATE_VOLTAGE_PATTERN   Create a voltage pattern for one subject.
%
%  subj = create_voltage_pattern(subj, pat_name, params, res_dir)
%
%  INPUTS:
%      subj:  a subject object. See get_sessdirs.
%
%  pat_name:  string identifier for the pattern.
%
%    params:  structure that specifies options for pattern creation. See below
%             for options.
%
%   res_dir:  path to the directory to save results. patterns will be saved in
%             [res_dir]/patterns; if events are modified, new events will be 
%             saved in [res_dir]/events.
%
%  OUTPUTS:
%      subj:  a modified subject object, with a "pat" object named pat_name 
%             added.
%
%  PARAMS:
%  All fields are optional. Defaults are shown in parentheses.
%  Events
%   evname          - name of the events object to use. ('events')
%   replace_eegfile - [N X 2] cell array, where each row contains two strings
%                     to be passed into strrep, to change the eegfile field in
%                     events ({})
%   eventFilter     - input to filterStruct which designates which events to 
%                     include in the pattern ('')
%   eventbins       - 
%   eventbinlabels  - 
%   kthresh         - kurtosis threshold; scalar indicating the maximum 
%                     allowable kurtosis for an event before it is excluded 
%                     (5)
%
%  Channels
%   chanFilter      - used to choose which channels to include in the pattern. 
%                     Can a string to pass into filterStruct, or an array of 
%                     channel numbers to include ('')
%   chanbins        - 
%   chanbinlabels   - 
%
%  Time
%   resampledRate   - rate to resample to (500)
%   offsetMS        - time in milliseconds before each event to start the 
%                     pattern (-200)
%   durationMS      - duration in milliseconds of each epoch (2200)
%   relativeMS      - range of times relative to the start of each event to 
%                     use for baseline subtraction ([-200 0])
%   MSbins          - 
%   MSbinlabels     - 
%
%  Filtering
%   filttype        - type of filter to use (see buttfilt) ('stop')
%   filtfreq        - range of frequencies to filter ([58 62])
%   filtorder       - order of the filter (4)
%   bufferMS        - buffer in milliseconds to use during filtering (1000)
%
%  Z-transforming
%   ztransform      - logical; if true, voltage will be z-transformed relative
%                     to the baseline for that session/channel (false)
%   baseEventFilter - input to filterStruct; designates which events to
%                     include for calculating the baseline 
%                     (params.eventFilter)
%   baseOffsetMS    - time before each baseline event to start the baseline 
%                     period (-200)
%   baseDurationMS  - duration of each baseline event epoch (200)
%   baseRelativeMS  - range of times relative to the start of each event to 
%                     use for baseline subtraction (params.relativeMS)
%
%  File Management
%   lock            - if true, the pattern's file will be locked during 
%                     pattern creation, and unlock when the program finishes.
%                     Useful for processing multiple subjects in parallel on a
%                     cluster. (false)
%   overwrite       - if true, existing pattern files will be overwritten 
%                     (false)
%   updateOnly      - if true, the pattern will not be created, but a pattern
%                     object will be created and attached to the subject 
%                     object (false)
%
%   See also create_power_pattern.

% input checks
if ~exist('subj','var') || ~isstruct(subj)
  error('You must pass a subject object.')
elseif length(subj)>1
  error('You must pass only one subject.')
end
if ~exist('params','var')
  params = struct;
elseif ~isstruct(params)
  error('params must be a structure.')
end
if ~exist('pat_name','var')
  pat_name = 'volt_pattern';
elseif ~ischar(pat_name)
  error('pat_name must be a string.')
end
if ~exist('res_dir', 'var')
  error('You give a path to a directory in which to save results.')
elseif ~ischar(res_dir)
  error('res_dir must be a string.')
end

% sessVoltage and create_pattern will set our default parameters;
% just run it
subj = create_pattern(subj, @sessVoltage, params, pat_name, res_dir);
