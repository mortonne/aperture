function D = patsize(dim_info,dim)
%PATSIZE   Get the size of a pattern from its dim structure.
%
%  D = patsize(dim_info, dim)
%
%  INPUTS:
%  dim_info:  structure containing information about the
%             dimensions of a pattern. Created by
%             create_pattern.
%
%       dim:  optional; the dimension to return. If omitted,
%             an array with the size of each dimension is
%             returned. Can be either the number of a
%             dimension in the pattern matrix, or the name
%             of one the dimensions ('ev','chan','time','freq').
%
%  OUTPUTS:
%         D:  an array with the size of the pattern.

% input checks
if ~exist('dim_info','var') || ~isstruct(dim_info)
  error('You must pass a dim structure.')
end
if ~exist('dim','var')
  dim = [];
end

% mapping between fields and dimension numbers
D(1) = dim_info.ev.len;
D(2) = length(dim_info.chan);
D(3) = length(dim_info.time);
D(4) = length(dim_info.freq);

% return the requested dimension size
if ~isempty(dim)
  [name,number] = read_dim_input(dim);
  D = D(number);
end
