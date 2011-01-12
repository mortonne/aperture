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

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

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

