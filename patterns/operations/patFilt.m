function [pat,inds] = patFilt(pat,params)
%PATFILT   Filter the dimensions of a pat object.
%
%  [pat, inds] = patFilt(pat, params)
%
%  INPUTS:
%      pat:  a pattern object.
%
%   params:  structure specifying options for filtering the pattern.
%            See below for options.
%
%  OUTPUTS:
%      pat:  the modified pattern object.
%
%     inds:  cell array of the indices required to reference the
%            pattern and carry out the filtering.
%
%  PARAMS:
%   eventFilter - string to be input to filterStruct to filter events
%   chanFilter  - string filter for channels
%   timeFilter  - string filter for time
%   freqFilter  - string filter for frequency
%
%  EXAMPLE:
%   % filter the pattern object
%   params = struct('eventFilter', 'strcmp(type,''WORD'')');
%   [pat, inds] = patFilt(pat, params);
%
%   % filter the pattern matrix
%   pattern = load_pattern(pat);
%   pattern = pattern(inds{:});
%
%  See also modify_pattern, patBins, patMeans.

% input checks
if ~exist('pat','var') || ~isstruct(pat)
  error('You must input a pat object.')
end
if ~exist('params','var')
  params = struct;
end
if ~isfield(pat.dim.ev, 'modified')
  pat.dim.ev.modified = false;
end

% default parameters
params = structDefaults(params, ...
                        'eventFilter', '', ...
                        'chanFilter',  '',  ...
                        'chan_filter', [],  ...
                        'timeFilter',  '',  ...
                        'freqFilter',  '');

% initialize
inds = repmat({':'},1,4);

% events
if ~isempty(params.eventFilter)
  % load
  events = get_mat(pat.dim.ev);
	
	% filter
	inds{1} = inStruct(events, params.eventFilter);
	events = events(inds{1});
	pat.dim.ev = set_mat(pat.dim.ev, events);
end

% channels
% old way of filtering
if ~isempty(params.chanFilter)
  if ischar(params.chanFilter)
	  inds{2} = inStruct(pat.dim.chan, params.chanFilter);
	else
	  inds{2} = find(ismember([pat.dim.chan.number], params.chanFilter));
  end
	pat.dim.chan = pat.dim.chan(inds{2});
end
% experimental new way
if ~isempty(params.chan_filter)
  % unpack the parameters
  filt_fcn = params.chan_filter{1};
  filt_input = params.chan_filter{2};

  % run the filter function
  inds{2} = filter_struct(pat.dim.chan, filt_fcn, filt_input);
end

% time
if ~isempty(params.timeFilter)
	inds{3} = inStruct(pat.dim.time, params.timeFilter);
	pat.dim.time = pat.dim.time(inds{3});
end

% frequency
if ~isempty(params.freqFilter)
  inds{4} = inStruct(pat.dim.freq, params.freqFilter);
	pat.dim.freq = pat.dim.freq(inds{4});
end

% check the dimensions
psize = patsize(pat.dim);
if any(~psize)
  bad_dims = find(~psize);
  msg = '';
  for dim_number=bad_dims
    [i,j,name] = read_dim_input(dim_number);
    msg = [msg sprintf('%s dimension filtered into oblivion.\n', name)];
  end
	error('eeg_ana:patFilt:EmptyPattern', msg);
end
