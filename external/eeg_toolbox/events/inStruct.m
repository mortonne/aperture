function ind = inStruct(events,expr,varargin)
%inStruct - Return logical indexes that match an expression.
%
% Return the indexes that match an evaluated expression.  You can
% include any combination of structure fields in your
% expression to evaluate by logical operators.  See the example
% expressions below.
%
% An added feature is that if you enclose your expr string in curly
% braces (for example, expr = {'length(subjects)>5 & p(2,3)<.05'}), the function
% will loop over each row of the structure and evaluate the expression
% instead of applying the expression to the entire structure at
% once.  This allows you to do more complex queries of your
% structure if it contains cell arrays and multidimensional matrixes.
%
% FUNCTION:
%   ind = inStruct(events,expr,varargin)
%
% INPUT ARGS:
%   events = events; % events structure to analyze
%   expr = 'rt > 1000 & ismember(subject,varargin{1})'; % expression to eval.
%   varargin = subj;  % Optional args passed in that can
%                  %  be used in the expr.  Here subj is a cell array
%                  %  of subject strings.
%
% OUTPUT ARGS:
%   ind - The logical indexes into events matching the expression
%

% CHANGES:
%
% 1/8/06 - PBS - Added ability to loop for more complex queries.
%

% set starting indexes to everything
ind = logical(ones(length(events),1));

% see if we should loop over each event (non vectorized, so slower)
doLoop = 0;
if iscell(expr)
  doLoop = 1;
  expr = expr{1};
end

if length(expr) > 0
  % get the field names
  fnames = fieldnames(events);
  
  for f = 1:length(fnames)
    % set the expression to replace
    r_exp = ['\<' fnames{f} '\>'];
    
    % set the replacement
    if doLoop
      r_str = ['events(i).' fnames{f}];
    else
      r_str = ['getStructField(events,''' fnames{f} ''')'];
    end
    
    % eval the expression
    expr = regexprep(expr,r_exp,r_str);
  end
  
  % get the indexes
  %ind = eval(['find(' expr ')']);
  if doLoop
    % must loop over each event
    for i = 1:length(events)
      ind(i) = eval(expr);
    end
  else
    % vectorized
    ind = eval(expr);
  end
end


