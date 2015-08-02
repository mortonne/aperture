function res = strfound(txt,pattern)
%STRFOUND - Wraps strfind to return boolean if pattern is in text
%
% This function wraps the STRFIND function, which returns a cell
% array indicating the index where a pattern is found in each
% string passed in.  In cases where we only want to know if a
% pattern is found in text, this will return a logical array
% indicating if the pattern was if the text.
%
% FUNCTION:
%   res = strfound(text,pattern)
%
% INPUT ARGS:
%   txt = {'hello','world'};  % String or cell array of strings
%   pattern = 'l';             % pattern to look for in strings
%
% OUTPUT ARGS:
%   res - logical array of whether pattern was found in text.
%
%

% % call to strfind
% x = strfind(txt,pattern);

% % process the strfind results
% if iscell(x)
%   res = logical(zeros(size(x)));
%   for i = 1:length(res)
%     res(i) = ~isempty(x{i});
%   end
% else
%   % was just single string
%   res = isempty(x);
% end

% new way 
if iscell(txt)
  % reserve memory for output parameter
  res = logical(zeros(size(txt)));
  % iteratively find string in cell array
  for i = 1:numel(txt)
    res(i) = ~isempty(strfind(txt{i},pattern));
  end
else
  res = ~isempty(strfind(txt,pattern));
end
