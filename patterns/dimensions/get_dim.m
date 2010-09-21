function dim = get_dim(dim_info, dim_id)
%GET_DIM   Get information about a dimension.
%
%  dim = get_dim(dim_info, dim_id)
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
%       dim:  structure with information about the dimension.
%
%  EXAMPLES:
%   % load events dimension info from a pat object
%   events = get_dim(pat.dim, 'ev');
%
%   % load channel information from a subject
%   chan = get_dim(subj, 'chan');

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
if ~ismember(dim_name, fieldnames(dim_info))
  error('dim_info has no information about "%s" dimension.', dim_name)
end

% get the corresponding subfield
dim = dim_info.(dim_name);

% if necessary, load the info from disk
if isfield(dim, 'file') || isfield(dim, 'mat')
  dim = get_mat(dim);
end

