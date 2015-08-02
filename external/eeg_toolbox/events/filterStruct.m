function [expr_events,ind] = filterStruct(events,expr,varargin)
%FILTERSTRUCT - Return the events that match an expression.
%
% Return the events that match an evaluated expression.  You can
% include any combination of events structure fields in your
% expression to evaluate by logical operators.  See the example
% expressions below:
%
% FUNCTION:
%   [expr_events,ind] = filterStruct(events,expr,varargin)
%
% INPUT ARGS:
%   events = events; % events structure to analyze
%   expr = 'rt > 1000 & ismember(subject,varargin{1})'; % expression to eval.
%   varargin = subj;  % Optional args passed in that can
%                  %  be used in the expr.  Here subj is a cell array
%                  %  of subject strings.
%
% OUTPUT ARGS:
%   expr_events - The events matching the expression
%   ind - The logical indexes into the initial struct that give rise to expr_events
%

if isempty(events)
  expr_events = events;
  ind = [];
  return
end

if isa(expr, 'function_handle')
  ind = expr(events);
elseif length(expr) > 0
  % get the indexes
  ind = inStruct(events,expr,varargin{:});
else
  ind = true(size(events));
  expr_events = events;
  return
end

% return the events
expr_events = events(ind);



