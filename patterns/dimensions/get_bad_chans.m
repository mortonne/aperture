function [bad_chans,eeg_ind] = get_bad_chans(eeg_files,bad_chan_files)
%GET_BAD_CHANS   Get a list of bad channels for given EEG files.
%
%  [bad_chans, eeg_ind] = get_bad_chans(eeg_files, bad_chan_files)
%
%  INPUTS:
%  eeg_files:  a cell array of roots for EEG filenames.
%              e.g. {session_0/eeg/eeg.reref/LTP001_13Mar08_1417, ...}
%
%  bad_chan_files:  cell array of paths to bad channel files. Paths must
%              be relative to the parent directory of each EEG file.
%              Default: {'bad_chan.txt'}
%
%  OUTPUTS:
%  bad_chans:  a cell array with one cell for each unique string in
%              eeg_files; each cell contains an array of channel numbers
%              indicating the channels that were labeled as "bad" for
%              that EEG file.
%
%    eeg_ind:  an array the same length as eeg_files, which gives the
%              index of each eeg_file in the bad_chans cell array.
%
%  EXAMPLE:
%   % get bad channel information for an events structure
%   [bad_chans, eeg_ind] = get_bad_chans({events.eegfile});
%
%   % get a list of bad channels for event 23:
%   bc = bad_chans{eeg_ind(23)};

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
if ~exist('eeg_files','var') || ~iscell(eeg_files)
  error('You must pass a cell array of EEG files.')
end
if ~exist('bad_chan_files','var')
  bad_chan_files = {'bad_chan.txt'};
end
if ~iscell(bad_chan_files)
  bad_chan_files = {bad_chan_files};
end

% get all unique EEG files
uniq_eeg_files = unique(eeg_files);

% initialize
bad_chans = cell(1,length(uniq_eeg_files));
eeg_ind = NaN(1,length(eeg_files));

% get bad channels for each unique EEG file
for i=1:length(uniq_eeg_files)
  % write out the indices for this EEG file
  eeg_ind(strcmp(uniq_eeg_files{i}, eeg_files)) = i;
  
  % assume that we passed in something like the eegfile field in the
  % standard events structure
  eeg_dir = fileparts(uniq_eeg_files{i});

  % read in the channels
  bad_chans{i} = read_bad_channels(eeg_dir, bad_chan_files);
end


function bad_channels = read_bad_channels(eeg_dir,bad_chan_files)
  bad_channels = [];
  for i=1:length(bad_chan_files)
    fname = fullfile(eeg_dir, bad_chan_files{i});
    if ~exist(fname,'file')
      fprintf('Warning: bad channels file not found: %s\n', fname)
      continue
    end
    
    chans = read_chans_file(fname);
    bad_channels = [bad_channels, chans];
  end
  
  bad_channels = unique(bad_channels);
%endfunction
