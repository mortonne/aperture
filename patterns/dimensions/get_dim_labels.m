function labels = get_dim_labels(dim_info, dim_id)
%GET_DIM_LABELS   Get the numeric values of a dimension.
%
%  labels = get_dim_labels(dim_info, dim_id)
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
%    labels:  cell array of string labels for the requested dimension.

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

if strcmp(dim_name, 'ev')
  dim_info.ev = get_mat(dim_info.ev);
  if ~isfield(dim_info.ev, 'label')
    error('events must contain a "label" field.')
  end
end

labels = {dim_info.(dim_name).label};

