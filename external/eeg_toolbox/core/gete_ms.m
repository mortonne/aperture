function EEG = gete_ms(channel, events, DurationMS, OffsetMS, varargin)
%GETE_MS - Get EEG event data based on MSec ranges instead of samples.
% 
% Returns data from an eeg file.  User specifies the channel,
% duration, and offset along with an event.  The event struct MUST
% contain both 'eegfile' and 'eegoffset' members.
%
% You can optionally resample the data with the Signal Toolbox's
% resample function.  The resampling occurs following the filter.
% Use the resampling with caution because the we have not provent
% that the spectral properties of the data do not change dramatically.
%
% NOTE: All events must have the same sampling rate.
%
% FUNCTION:
%   EEG=gete_ms(channel,events,durationMS,offsetMS,bufferMS,filtfreq,filttype,filtorder,resampledRate,RelativeMS)
%
% INPUT ARGS:
%   channel = 3;            % the electrode #
%   events = events(8:12);  % event struct to extract [eegfile eegoffset]
%   durationMS = 2000;      % signal time length in samples
%   offsetMS = 0;           % offset at which to start in samples
%   bufferMS = 1000;        % buffer (needed for filtering or resampling)
%                           %   default is 0
%   filtfreq = [58 62];     % Filter freq (depends on type, see buttfilt)
%                           %   default is []
%   filttype = 'stop';      % Filter type (see buttfilt)
%   filtorder = 1;          % Filter order (see buttfilt)
%   resampledRate = 200;    % Sample rate of the returned data
%   RelativeMS = [-200 0];  % Range for use with the relative subtraction
%
% OUTPUT ARGS:
%   EEG(Trials,Time) - The data from the file
%

% 12/18/07 - MvV - changed the indices into readbytes when saving
% to EEG, such that it was always fit and not be affected by
% rounding differences.
% 11/29/04 - PBS - Changed round to fix to fix range problem
% 4/20/04 - PBS - Added Relative Range subtraction

% input checks
if ~exist('channel','var') || ~isnumeric(channel)
  error('You must specify a channel number.')
elseif ~exist('events','var') || ~isstruct(events)
  error('You must pass an events structure.')
elseif ~exist('DurationMS','var')
  error('You must specify the duration of the epoch.')
elseif ~exist('OffsetMS','var')
  error('You must specify the offset of the epoch.')
end

% options
defaults.bufferMS = 0;
defaults.filtfreq = [];
defaults.filttype = 'stop';
defaults.filtorder = 1;
defaults.resampledRate = [];
defaults.relativeMS = [];
old_args = {'bufferMS' 'filtfreq' 'filttype' 'filtorder' ...
            'resampledRate' 'relativeMS'};
old_classes = {'numeric' 'numeric' 'char' 'numeric' 'numeric' 'numeric'};
params = list2propval(varargin, defaults, 'fields', old_args, ...
                      'classes', old_classes);
BufferMS = params.bufferMS;
filtfreq = params.filtfreq;
filttype = params.filttype;
filtorder = params.filtorder;
resampledRate = params.resampledRate;
RelativeMS = params.relativeMS;

% get initial data info
[samplerate,nBytes,dataformat,gain] = GetRateAndFormat(events(1));
if isempty(resampledRate)
  resampledRate = samplerate;
end
resampledRate = round(resampledRate);

% base final datasize on resampled data
final_duration = ms2samp(DurationMS, resampledRate);
final_offset = ms2samp(OffsetMS, resampledRate);
final_buffer = ms2samp(BufferMS, resampledRate);

% get info about each data file referenced by the
% events structure
eegfiles = unique({events.eegfile});
for i=1:length(eegfiles)
  if isempty(eegfiles{i})
    num_bad_events = length(find((strcmp({events.eegfile},''))));
    warning('eeg_toolbox:gete_ms:EventEEGNotFound', ...
            '%d events have an empty eegfile field.', num_bad_events)
    continue
  end
  
  % read info about this file's EEG data
  paramdir = fileparts(eegfiles{i});
  c = cell(1,4);
  [c{:}] = GetRateAndFormat(paramdir);

  % open the file
  fid = open_eegfile(eegfiles{i}, channel);

  % set event durations from rate
  duration = ms2samp(DurationMS+(2*BufferMS), c{1});
  offset = ms2samp(OffsetMS-BufferMS, c{1});
  
  % make a structure with all the info
  c = [eegfiles{i} fid duration offset c];
  f = {'eegfile','eegfilehandle','duration','offset',...
       'samplerate','nBytes','dataformat','gain'};
  eeginfo(i) = cell2struct(c, f, 2);
end

% allocate space
EEG = NaN(length(events), final_duration);

for e = 1:length(events)
  % info about the EEG data for this event
  if isempty(events(e).eegfile)
    % no info for this file; can't get data, so leave this event
    % as NaNs
    continue
  end
  eegfilename = events(e).eegfile;
  info = eeginfo(strcmp({eeginfo.eegfile}, eegfilename));
  
  % get the handle to this EEG file
  eegfile = info.eegfilehandle;
  
  % read the eeg data
  thetime = info.offset + events(e).eegoffset;      
  status = fseek(eegfile, info.nBytes * thetime, -1);
  if status == 0
      readbytes = fread(eegfile, info.duration, info.dataformat)';
  elseif status == -1
      warning('EEGTOOLBOX:GETEMS:NODATA', ...
              '%s: eeg data for event %d were not found', eegfilename, e);
      readbytes = NaN(1, info.duration);
  end

  % make sure we read in a whole event
  if length(readbytes) ~= info.duration
     warning('EEGTOOLBOX:GETEMS:INCOMPLETEDATA', ...
           '%s: only %d of %d samples read for event %d -- appending nans', ...
             eegfilename, length(readbytes), info.duration, e);
     readbytes = [readbytes NaN(1, info.duration - length(readbytes))];
  end

  % filter
  if ~isempty(filtfreq)
    readbytes = buttfilt(readbytes, filtfreq, info.samplerate, ...
                         filttype, filtorder);
  end

  % resample
  if resampledRate ~= info.samplerate
    readbytes = resample(readbytes, round(resampledRate), ...
                         round(info.samplerate));
  end

  % append the data
  EEG(e,:) = readbytes(final_buffer + 1:(final_buffer + final_duration));
end

% close all open EEG files
fclose('all');

% relative baseline correction
if length(RelativeMS) == 2
  % get the average for the range
  relative = ms2samp(RelativeMS, resampledRate);
  relative = relative - final_offset + 1;
  relative(2) = relative(2) - 1;
  
  % calculate the relative
  releeg = mean(EEG(:,(relative(1):relative(2))),2);

  % subtract the baseline
  EEG = EEG - repmat(releeg, 1, size(EEG,2));
end 

% gain multiplication
EEG = EEG .* gain;


function fid = open_eegfile(fileroot, channel)
  % set the channel filename
  fname = sprintf('%s.%03i', fileroot, channel);
  fid = fopen(fname,'r','l'); % NOTE: the 'l' means that it
                                   % came from a PC! 
  if fid == -1
    fname = sprintf('%s%03i', fileroot, channel); % now try unpadded lead#
    fid = fopen(fname,'r','l');
  end
  if fid == -1
    fname = sprintf('%s.%i', fileroot, channel); % now try unpadded lead#
    fid = fopen(fname,'r','l');
  end
  if fid == -1
    % giving up
    error('EEG file not found for: %s channel %d.', fileroot, channel);
  end
%endfunction
