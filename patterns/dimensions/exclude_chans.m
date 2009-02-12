function include = exclude_chans(chan, chan_numbers)
%EXCLUDE_CHANS   Exclude channels by number.
%
%  include = exclude_chans(chan, chan_numbers)
%
%  We probably want a more general version of this that is as flexible
%  as ismember and can take any field as input. That function would
%  handle 90% of most users' filtering needs. But what should the name be?

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
