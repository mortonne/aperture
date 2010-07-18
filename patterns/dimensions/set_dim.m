function dim_info = set_dim(dim_info, dim_id, dim)
%SET_DIM   Update information about a dimension.
%
%  dim_info = set_dim(dim_info, dim_id, dim)
%
%  INPUTS:
%  dim_info:  structure with information about the dimensions of a
%             pattern.  (normally stored in pat.dim).
%
%    dim_id:  either a string specifying the name of the dimension
%             (can be: 'ev', 'chan', 'time', 'freq'), or an integer
%             corresponding to the dimension in the actual matrix.
%
%       dim:  new dimension structure to set.
%
%  OUTPUTS:
%  dim_info:  updated dim info structure.
%
%  EXAMPLES:
%   % add a new field to a pattern's events structure
%   events = get_dim(pat.dim, 'ev');
%   [events.subject] = deal('subj00');
%   pat.dim = set_dim(pat.dim, 'ev', events);

% input checks
if ~exist('dim_info', 'var') || ~isstruct(dim_info)
  error('You must pass a dim info structure.')
elseif ~exist('dim_id', 'var')
  error('You must indicate the dimension.')
elseif ~(ischar(dim_id) || isnumeric(dim_id))
  error('dim_id must be a string or an integer.')
end

% get the name of the dimension in the dim_info struct
dim_name = read_dim_input(dim_id);

% get the corresponding subfield
if isfield(dim_info.(dim_name), 'file')
  % saving to disk is supported for this dimension
  dim_info.(dim_name) = set_mat(dim_info.(dim_name), dim);
else
  % just set it as the value of the field
  dim_info.(dim_name) = dim;
end

