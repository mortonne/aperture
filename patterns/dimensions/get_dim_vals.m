function vals = get_dim_vals(dim_info, dim_id)
%GET_DIM_VALS   Get the numeric values of a dimension.
%
%  vals = get_dim_vals(dim_info, dim_id)
%
%  INPUTS:
%  dim_info:  structure with information about the dimensions of a
%             pattern.  (normally stored in pat.dim).
%
%    dim_id:  either a string specifying the name of the dimension
%             (can be: 'ev', 'chan', 'time', 'freq'), or an integer
%             corresponding to the dimension in the actual matrix.
%
%  OUTPUTS:
%      vals:  vector of numeric values for the requested dimension.

% input checks
if ~exist('dim_info', 'var') || ~isstruct(dim_info)
  error('You must pass a dim info structure.')
elseif ~exist('dim_id', 'var')
  error('You must indicate the dimension.')
elseif ~(ischar(dim_id) || isnumeric(dim_id))
  error('dim_id must be a string or an integer.')
end

% get the short name of the dimension
dim_name = read_dim_input(dim_id);

switch dim_name
 case {'ev', 'chan'}
  % these dimensions don't really have numeric values; just return the
  % indices
  vals = 1:patsize(dim_info, dim_id);
 case {'time', 'freq'}
  dim = get_dim(dim_info, dim_name);
  if ~isfield(dim, 'avg')
    error('time and frequency dimensions must contain an "avg" field.')
  end
  vals = [dim.avg];
end

