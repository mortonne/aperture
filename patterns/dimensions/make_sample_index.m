function index = make_sample_index(eeg_offset, eeg_file)
%MAKE_SAMPLE_INDEX   Make an index that is unique for a set of samples.
%
%  Takes eeg_offset, which is the sample of the start of each event in
%  samples relative to the start of the recording and eeg_file, which
%  gives the recording, and returns an offset measure which is unique
%  across all recordings and has enough padding to allow for events form
%  separate recordings not overlapping.
%
%  index = make_sample_index(eeg_offset, eeg_file)
%
%  INPUTS:
%  eeg_offset:  vector of length events, containing the start of each
%               event in samples from the start of the recording.
%
%    eeg_file:  path to the file containing the recording for each
%               event.
%
%  OUTPUTS:
%       index:  vector with one element for each event containing a
%               unique samples measure.  No longer indicates time from
%               the start of the recording, but relative times are
%               preserved (with the exception of times between
%               recordings, which are assumed to be unimportant)

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

buffer = range(eeg_offset);
ufiles = unique(eeg_file);
for i = 1:length(ufiles)
  match = strcmp(eeg_file, ufiles{i});

  % add a buffer
  if i > 1
    eeg_offset(match) = eeg_offset(match) + prev_max + buffer;
  end
  prev_max = eeg_offset(max(find(match)));
end
index = eeg_offset;

