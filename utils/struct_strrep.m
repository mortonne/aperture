function s = struct_strrep(s, varargin)
%STRUCT_STRREP   Recursively run strrep on all strings in a structure.
%
%  s = struct_strrep(s, varargin)
%
%  INPUTS:
%         s:  structure containing strings to be modified.
%
%  varargin:  any number of string pairs, where the first is the string
%             to replace, and the second is the string to replace it
%             with.
%
%  OUTPUTS:
%         s:  modified structure.
%
%  EXAMPLE:
%   clear s
%   s.string = 'hello world!';
%   s.subfield.string = 'hi!';
%   s = struct_strrep(s, 'hi', 'hi, Dr. Nick', ...
%                     'hello world', 'hi, everybody');

% input checks
if ~exist('s', 'var')
  error('You must input a structure.')
elseif ~isstruct(s)
  error('s must be a structure.')
elseif ~iscellstr(varargin) || mod(length(varargin), 2)
  error('varargin must contain pairs of strings.')
end

fnames = fieldnames(s);
for i=1:length(fnames)
  fname = fnames{i};
  for j=1:numel(s)
    % get the field for this element of the structure
    f = s(j).(fname);

    % run strrep if applicable
    if isstr(f) || iscellstr(f)
      for r=1:2:length(varargin)
        to_replace = varargin{r};
        replacement = varargin{r+1};
        f = strrep(f, to_replace, replacement);
      end
    end

    % or call function recursively
    if isstruct(f)
      f = struct_strrep(f, varargin{:});
    end

    % we're done with this element; set it back in the structure
    s(j).(fname) = f;
  end
end

