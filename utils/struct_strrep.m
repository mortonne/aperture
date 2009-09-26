function s = struct_strrep(s, rep_str)
%STRUCT_STRREP   Recursively run strrep on all strings in a structure.
%
%  s = struct_strrep(s, rep_str)
%
%  INPUTS:
%        s:  structure containing strings to be modified.
%
%  rep_str:  cell array with one row per strrep command, where
%            rep_str{row, 1} and rep_str{row, 2} are the string to be
%            replaced and the replacement, respectively.  Rows are
%            evaluated in order.
%
%  OUTPUTS:
%        s:  modified structure.
%
%  EXAMPLE:
%   clear s rep_str
%   s.string = 'hello world!';
%   s.subfield.string = 'hi!';
%   rep_str(1,:) = {'hi', 'hi, Dr. Nick'};
%   rep_str(2,:) = {'hello world', 'hi, everybody'};
%   s = struct_strrep(s, rep_str);

% input checks
if ~exist('s', 'var')
  error('You must input a structure.')
elseif ~isstruct(s)
  error('s must be a structure.')
elseif ~exist('rep_str', 'var')
  error('You must input rep_str.')
elseif ~iscell(rep_str) || size(rep_str, 2)~=2
  error('rep_str must be a cell array with two columns.')
elseif ~iscellstr(rep_str)
  error('rep_str must contain strings.')
end

fnames = fieldnames(s);
for i=1:length(fnames)
  fname = fnames{i};
  for j=1:numel(s)
    % get the field for this element of the structure
    f = s(j).(fname);

    % run strrep if applicable
    if isstr(f) || iscellstr(f)
      for r=1:size(rep_str,1)
        f = strrep(f, rep_str{r,1}, rep_str{r,2});
      end
    end

    % or call function recursively
    if isstruct(f)
      f = struct_strrep(f, rep_str);
    end

    % we're done with this element; set it back in the structure
    s(j).(fname) = f;
  end
end

