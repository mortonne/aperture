function data = getStructField(events,field,expr,varargin);
%GETFIELD - Return data from a field in a structure.
%
% Return all the data from a single field in a structure.
% You can then use the returned data in logical comparisons to
% filter the events.
%
% FUNCTION:
%   data = getStructField(events,field,expr)
%
% INPUT ARGS:
%   events = events;   % Events structure to query
%   field = 'fileno';  % Field in events structure to query
%   expr = 'rt > 1000 & strcmp(subj,''BR018'')' % Optional expression to
%                                              % limit events. (Defaults to '')
%   varargin = subj; % Optional args for expr (see filterStruct for explaination)
%
% OUTPUT ARGS:
%   data- A vector or Cell array (If the field contained strings)
%   of the desired field's data.
%

if ~exist('expr','var')
  expr = '';
end

% see limit events first
if ~isempty(expr)
  events = filterStruct(events,expr,varargin{:});
end

if length(events) == 0
  x = [];
  return
end

% capture data in a cell array (_always_ works)
data = {events.(field)};

% see if we can reduce to a vector
vectorizable = ~any(cellfun(@isempty, data)) & ...
               all(cellfun(@isnumeric, data) | cellfun(@islogical, data));

if vectorizable
  data = [data{:}];
end

