function [eeg, time] = load_chan(fileroot, channel)
%LOAD_CHAN   Load raw EEG data from one channel.
%
%  [eeg, time] = load_chan(fileroot, channel)
%
%  INPUTS:
%  fileroot:  path to an EEG file. Do not include the prefix that indicates
%             the channel.
%
%   channel:  number of the channel to load.  If an array of two numbers is
%             specified, the returned EEG will be channel(1)-channel(2).
%
%  OUTPUTS:
%       eeg:  [1 X N samples] array of raw EEG data.

% input checks
if nargin < 2
  error('You must specify a channel to load.')
elseif ~ischar(fileroot)
  error('fileroot must be a string.')
elseif ~isnumeric(channel)
  error('channel must be numeric.')
end

% get file info
[samplerate,nBytes,dataformat,gain] = GetRateAndFormat(fileparts(fileroot));

% open and read the whole file into a vector
if length(channel)==1
  eeg = read_chan_eeg(fileroot, channel, dataformat);
elseif length(channel)==2
  eeg1 = read_chan_eeg(fileroot, channel(1), dataformat);
  eeg2 = read_chan_eeg(fileroot, channel(2), dataformat);
  eeg = eeg1 - eeg2;
else
  error('You may not specify more than two channels to load.')
end

% apply the gain
eeg = eeg * gain;

% set time in seconds from the beginning of the recording
step = 1000 / samplerate;
finish = (length(eeg) * step) - step;
time = (0:step:finish) / 1000;


function eeg = read_chan_eeg(fileroot, channel, dataformat)
  fid = open_eeg_file(fileroot, channel);
  eeg = fread(fid, inf, dataformat)';
  fclose(fid);
%endfunction
