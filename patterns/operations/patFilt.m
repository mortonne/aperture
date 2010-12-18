function [pat, inds] = patFilt(pat, varargin)
%PATFILT   Filter the dimensions of a pat object.
%
%  [pat, inds] = patFilt(pat, ...)
%
%  INPUTS:
%      pat:  a pattern object.
%
%  OUTPUTS:
%      pat:  the modified pattern object.
%
%     inds:  cell array of the indices required to reference the
%            pattern and carry out the filtering.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure.
%   eventFilter - string to be input to inStruct to filter events
%
%   chanFilter  - specifies which channels to include. May be of class:
%                        char - "expr" for inStruct
%                     numeric - list of channel numbers to include
%                  cell array - list of channel labels to include
%
%   timeFilter  - specifies times to include. May be of class:
%                     char - "expr" for inStruct
%                  numeric - range of times in milliseconds to include
%                            (bottom inclusive, top noninclusive), e.g.
%                            [0 500]
%
%   freqFilter  - specifies frequencies to include. May be of class:
%                     char - "expr" for inStruct
%                  numeric - inclusive range of frequencies in Hz to
%                            include, e.g. [4 8] to return frequencies
%                            in the theta band.
%
%  EXAMPLE:
%   % filter the pattern object
%   params = struct('eventFilter', 'strcmp(type,''WORD'')');
%   [pat, inds] = patFilt(pat, params);
%
%   % filter the pattern matrix
%   pattern = get_mat(pat);
%   pattern = pattern(inds{:});
%
%  See also filter_pattern.

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must input a pat object.')
end
if ~exist('params', 'var')
  params = struct;
end
if ~isfield(pat.dim.ev, 'modified')
  pat.dim.ev.modified = false;
end

% options
defaults.eventFilter = '';
defaults.chanFilter = '';
defaults.chan_filter = [];
defaults.timeFilter = '';
defaults.freqFilter = '';
[params, unused] = propval(varargin, defaults);

% initialize
inds = repmat({':'}, 1, 4);

% events
if ~isempty(params.eventFilter)
  % load
  events = get_dim(pat.dim, 'ev');
  
  % filter
  inds{1} = inStruct(events, params.eventFilter);
  events = events(inds{1});
  pat.dim = set_dim(pat.dim, 'ev', events, 'ws');
end

% channels
% old way of filtering
if ~isempty(params.chanFilter)
  if ischar(params.chanFilter)
    inds{2} = inStruct(get_dim(pat.dim, 'chan'), params.chanFilter);
  elseif iscellstr(params.chanFilter)
    % specifying labels
    [tf, loc] = ismember(params.chanFilter, get_dim_labels(pat.dim, 'chan'));
    inds{2} = loc(tf);
  elseif isnumeric(params.chanFilter)
    % specifying channel numbers
    [tf, loc] = ismember(params.chanFilter, get_dim_vals(pat.dim, 'chan'));
    inds{2} = loc(tf);
  else
    error('Invalid chanFilter input.')
  end
  chan = get_dim(pat.dim, 'chan');
  pat.dim = set_dim(pat.dim, 'chan', chan(inds{2}), 'ws');
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
  if isnumeric(params.timeFilter)
    bounds = params.timeFilter;
    ms = get_dim_vals(pat.dim, 'time');
    inds{3} = bounds(1) <= ms & ms < bounds(2);
  elseif ischar(params.timeFilter)
    inds{3} = inStruct(get_dim(pat.dim, 'time'), params.timeFilter);
  end
  time = get_dim(pat.dim, 'time');
  pat.dim = set_dim(pat.dim, 'time', time(inds{3}), 'ws');
end

% frequency
if ~isempty(params.freqFilter)
  if isnumeric(params.freqFilter)
    bounds = params.freqFilter;
    freq = get_dim_vals(pat.dim, 'freq');
    inds{4} = bounds(1) <= freq & freq <= bounds(2);
  elseif ischar(params.freqFilter)
    inds{4} = inStruct(get_dim(pat.dim, 'freq'), params.freqFilter);
  end
  freq = get_dim(pat.dim, 'freq');
  pat.dim = set_dim(pat.dim, 'freq', freq(inds{4}), 'ws');
end

% check the dimensions
psize = patsize(pat.dim);
if any(~psize)
  bad_dims = find(~psize);
  msg = '';
  for dim_number=bad_dims
    [i, j, name] = read_dim_input(dim_number);
    msg = [msg sprintf('%s dimension filtered into oblivion.\n', name)];
  end
  error('eeg_ana:patFilt:EmptyPattern', msg);
end

