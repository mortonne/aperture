function include = exclude_chans(chan, chan_numbers)
%EXCLUDE_CHANS   Exclude channels by number.
%
%  include = exclude_chans(chan, chan_numbers)
%
%  We probably want a more general version of this that is as flexible
%  as ismember and can take any field as input. That function would
%  handle 90% of most users' filtering needs. But what should the name be?

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

if length(chan)>1
  error('You must pass in one channel at a time.')
  elseif ~exist('chan_numbers','var')
  error('You must specify which channels to exclude.')
  elseif ~isnumeric(chan_numbers)
  error('chan_numbers must be a vector.')
end

if ismember(chan.number, chan_numbers)
  % this channel is bad; exclude it
  include = false;
  else
  % include this channel
  include = true;
end
