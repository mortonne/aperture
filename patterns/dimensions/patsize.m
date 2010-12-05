function D = patsize(dim_info, dim)
%PATSIZE   Get the size of a pattern from its dim structure.
%
%  D = patsize(dim_info, dim)
%
%  INPUTS:
%  dim_info:  structure containing information about the dimensions of a
%             pattern.
%
%       dim:  optional; the dimension to return. If omitted, an array
%             with the size of each dimension is returned. Can be either
%             the number of a dimension in the pattern matrix, or the
%             name of one the dimensions ('ev','chan','time','freq').
%
%  OUTPUTS:
%         D:  an array with the size of the requested dimension(s).

% input checks
if ~exist('dim', 'var')
  dim = 1:4;
end

% mapping between fields and dimension numbers
for i = 1:length(dim)
  D(i) = get_dim_len(dim_info, read_dim_input(dim(i)));
end

function len = get_dim_len(dim_info, dim_name)

  if isfield(dim_info.(dim_name), 'len')
    len = dim_info.(dim_name).len;
  else
    dim = get_dim(dim_info, dim_name);
    len = length(dim);
  end

