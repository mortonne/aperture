function dim = init_dim(dim_name, varargin)
%INIT_DIM   Initialize a new dimension object.
%
%  dim = init_dim(dim_name, ...)
%
%  INPUTS:
%  dim_name:  name of the dimension to initialize.
%
%  OUTPUTS:
%      dim:  the dimension object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   file     - path to the file where info for this dimension is
%              stored. ('')
%   len      - length of this dimension. ([])
%   modified - if true, this dimension has been modified since last
%              saved. (false)

% options
defaults.file = '';
defaults.len = [];
defaults.modified = false;
params = propval(varargin, defaults);

% create the dim structure
dim = struct;
dim.type = dim_name;
dim.file = params.file;
dim.len = params.len;
dim.modified = params.modified;

