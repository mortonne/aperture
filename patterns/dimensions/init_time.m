function time = init_time(ms_vals, labels)
%INIT_TIME   Initialize a time dimension.
%
%  time = init_time(ms_vals, labels)
%
%  INPUTS:
%  ms_vals:  vector of time values in milliseconds.
%
%   labels:  (optional) cell array of strings giving labels for each
%            time bin.
%
%  OUTPUTS:
%     time:  struct with information about a time dimension.

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
if ~exist('ms_vals', 'var') || isempty(ms_vals)
  time = struct('MSvals', [],  'avg', [],  'label', '');
  return
elseif ~isnumeric(ms_vals)
  error('ms_vals must be numeric.')
end
if ~exist('labels', 'var')
  labels = {};
elseif ~iscellstr(labels)
  error('labels must be a cell array of strings.')
elseif length(labels) ~= length(ms_vals)
  error('labels must be the same length as ms_vals.')
end

% make the time struct, with one element for each time bin
ms_vals_cell = num2cell(ms_vals);
if isempty(labels)
  % if no user-specified labels, print default labels
  labels = cellfun(@(x)sprintf('%d ms', x), ms_vals_cell, 'UniformOutput', ...
                   false);
end
time = struct('MSvals', ms_vals_cell, 'avg', ms_vals_cell, 'label', labels);

