function [bad_chans,eeg_ind] = get_bad_chans(eeg_files)
%GET_BAD_CHANS   Get a list of bad channels for given EEG files.
%
%  [bad_chans, eeg_ind] = get_bad_chans(eeg_files)
%
%  INPUTS:
%  eeg_files:  a cell array of roots for EEG filenames.
%              e.g. {session_0/eeg/eeg.reref/LTP001_13Mar08_1417, ...}
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

% get all unique EEG files
uniq_eeg_files = unique(eeg_files);

% initialize
bad_chans = cell(1,length(uniq_eeg_files));
eeg_ind = NaN(1,length(eeg_files));

% get bad channels for each unique EEG file
for i=1:length(uniq_eeg_files)
  % assume that we passed in something like the eegfile field in the
  % standard events structure
  eeg_dir = fileparts(uniq_eeg_files{i});
  
  % read in the channels
  temp = textscan(fopen(fullfile(eeg_dir, 'bad_chan.txt')), '%d');
  bad_chans{i} = temp{1};
  
  % write out the indices for this EEG file
  eeg_ind(strcmp(uniq_eeg_files{i}, eeg_files)) = i;
end
