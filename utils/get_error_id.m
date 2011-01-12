function id = get_error_id(err)
%GET_ERROR_ID   Return the last segment of an error identifier.
%
%  id = get_error_id(err)

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
if ~exist('err','var') || ~isa(err, 'MException')
  error('eeg_ana:get_error_id:NoError', 'You must pass an MException.')
end

% use a regular expression to get the last segment of the id
id = regexp(err.identifier, '(?<=:)\w+$', 'match');
if ~isempty(id)
  id = id{1};
else
  % if no ID, just return an empty string
  id = '';
end
