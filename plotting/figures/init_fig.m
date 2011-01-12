function fig = init_fig(name, file, source)
%INIT_FIG   Initialize a struct to hold metadata about figures.
%
%  fig = init_fig(name, file, source)
%
%  INPUTS:
%     name:  string identifier for this fig object.
%
%     file:  string or cell array of strings giving paths to
%            saved figures.
%
%   source:  name of the parent object.
%
%  OUTPUTS:
%      fig:  a standard figure object.
%
%  See also create_fig.

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

% input checks
if ~exist('name','var')
  name = '';
elseif ~ischar(name)
  error('name must be a string.')
end
if ~exist('file','var')
  file = '';
elseif (~ischar(file) && ~iscell(file))
  error('file must be a string or a cell array of strings.')
elseif ischar(file)
  if ~exist(file,'file')
    error('File does not exist: %s', file)
  end
elseif iscell(file)
  if ~all(cellfun(@ischar, file))
    error('file must be a string or a cell array of strings.')
  end
end
if ~exist('source','var')
  source = '';
elseif ~ischar(source)
  error('source must be a string.')
end

if iscell(file) & isempty(file)
  file = {''};
end

% create the fig structure
fig = struct('name',name, 'file','', 'source',source);

% now add the file cell array
fig.file = file;
