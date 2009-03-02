function [pattern,events] = load_pattern(pat,params)
%LOAD_PATTERN   Load a pattern from a pat object.
%
%  [pattern, events] = load_pattern(pat, params)
%
%  If pat.file is a string, this is the same as load(pat.file), except
%  the events structure is also loaded.
%
%  If pat.file is a cell array, the pattern is assumed to be saved in 
%  slices, and will be reconstituted by loading up all the files in 
%  pat.file and concatenating along pat.dim.splitdim.
%
%  INPUTS:
%      pat:  a pat object.
%
%   params:  structure with fields that specify options for loading
%            the pattern.
%
%  OUTPUTS:
%  pattern:  an [events X channels X time X frequency] matrix.
%
%   events:  a structure with information about the events dimension
%            of a pattern. If there is only one output argument,
%            we won't bother to load this.
%
%  PARAMS:
%   'loadSingles' If true (default is false), the pattern will
%                 be loaded as an array of singles
%
%  NOTES:
%   In the future, may remove loading of events, stop using a params 
%   structure, and remove the loadSingles option.
%
%  See also create_pattern, split_pattern.

% input checks
if ~exist('pat','var')
  error('You must pass a pat object.')
  elseif isempty(pat)
  error('The input pat object is empty.')
end
if ~exist('params', 'var')
  params = struct;
end

% set default parameters
params = structDefaults(params, 'loadSingles',0, 'patnum', []);

% load the pattern
if iscell(pat.file) % pattern is split
  
  if isfield(pat.dim,'splitdim') && ~isempty(pat.dim.splitdim)
    % concatenate along the split dimension to reform the pattern
    pattern = NaN(patsize(pat.dim));
    allDim = {':',':',':',':'};
    for i=1:length(pat.file)
      % load this slice
      s = load(pat.file{i});
      
      % add it to the matrix
      ind = allDim;
      ind{pat.dim.splitdim} = i;
      pattern(ind{:}) = s.pattern;
    end
    
    else
    % if pat.file is a cell array and there's no information about 
    % which dimension to concatenate along, give up
    error('pat.dim must have a ''splitdim'' field.')
  end
  
  else % there is just one file; load it up
  load(pat.file);
end

% change to lower precision if desired
if params.loadSingles
	pattern = single(pattern);
end

% load events
if nargout==2
  events = loadEvents(pat.dim.ev.file);
else
  events = struct;
end
