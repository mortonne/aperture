function EEG=gete(channel,events,duration,offset,buffer,filtfreq,filttype,filtorder,resampledrate)
%GETE - Get EEG event data.
% 
% Returns data from an eeg file.  User specifies the channel,
% duration, and offset along with an event.  The event struct MUST
% contain both 'eegfile' and 'eegoffset' members.
%
% If the duration is set to 0, then it will return a cell array of
% the entire data from each unique file in the events structure.
% It will ignore the offset and buffer variables.
%
% FUNCTION:
%   EEG=gete(channel,events,duration,offset,buffer,filtfreq,filttype,filtorder,resampledrate)
%
% INPUT ARGS:
%   channel = 3;            % the electrode #
%   events = events(8:12);  % event struct to extract [eegfile eegoffset]
%   duration = 512;         % signal time length in samples (of the
%                           % original duration of the data)
%   offset = 0;             % offset at which to start in samples
%                           % (in units of the original data)
%   buffer = 256;           % buffer (needed for filtering)
%                           %   default is 0
%   filtfreq = [59.5 60.5]; % Filter freq (depends on type, see buttfilt)
%                           %   default is []
%   filttype = 'stop';      % Filter type (see buttfilt)
%   filtorder = 1;          % Filter order (see buttfilt)
%   resampledrate = 256     % (optinal) - resampled the data
%
% OUTPUT ARGS:
%   EEG - The data from the file
%

% 2006/8/4 - MvV: fixed bug in case of fractionated durations
% 2006/1/20 - MvV: added in resampling, similar to gete_ms.m
% 2004/3/5 - PBS: Now reads in entire unique file if duration is 0
% 2003/12/9 - PBS: Added which event number to read warning

% check the arg
if nargin < 9
  resampledrate = [];
if nargin < 8
  filtorder = 1;
  if nargin < 7
    filttype = 'stop';
    if nargin < 6
      filtfreq = [];
      if nargin < 5
	buffer = 0;
	if nargin<4 
	  offset=0; 
	end; 
      end
    end
  end
end
end

% get data info
[samplerate,nBytes,dataformat,gain] = GetRateAndFormat(events(1));
samplerate = round(samplerate);

if isempty(resampledrate)
  resampledrate = samplerate;
end
resampledrate = round(resampledrate);

final_duration = fix(duration*resampledrate/samplerate);
final_offset = fix(offset*resampledrate/samplerate);
final_buffer = fix(buffer*resampledrate/samplerate);

% see if getting for each event or all unique files
if duration == 0
  % getting for all unique files
  uFiles = unique({events.eegfile});
  if isempty(uFiles{1})
    uFiles = uFiles(2:end);
  end
  
  EEG = cell(1,length(uFiles));
  
  % loop over files
  for f = 1:length(uFiles)
    % set the channel filename
    eegfname=sprintf('%s.%03i',uFiles{f},channel);
    
    eegfile=fopen(eegfname,'r','l'); % NOTE: the 'l' means that it came from a PC!
    if(eegfile==-1)
      eegfname=sprintf('%s%03i',uFiles{f},channel); % now try unpadded lead#
      eegfile=fopen(eegfname,'r','l');
    end
    if(eegfile==-1)
      eegfname=sprintf('%s.%i',uFiles{f},channel); % now try unpadded lead#
      eegfile=fopen(eegfname,'r','l');
    end
    
    % tell if not open
    if eegfile==-1
      % did not open
      error('ERROR: EEG File not found: %s.\n',eegfname);
    end
    
    % read the entire file
    EEG{f} = fread(eegfile,inf,dataformat)';
    
    % close the file
    fclose(eegfile);
    
    % see if filter the data
    if length(filtfreq) > 0
      EEG{f}=buttfilt(EEG{f},filtfreq,samplerate,filttype,filtorder);
    end
    
    % see if resample
    if resampledrate ~= samplerate
      % do the resample
      EEG{f} = resample(EEG{f},round(resampledrate),round(samplerate));
      %readbytes = dsamp(readbytes,round(samplerate),round(resampledRate));
    end	
    
    % apply the gain
    EEG{f} = EEG{f}.*gain;
  end
  
else 
  % getting for each event
  % allocate space
  EEG = zeros(length(events),final_duration+(2*final_buffer));
  
  for e = 1:length(events)


    % set the channel filename
    eegfname=sprintf('%s.%03i',events(e).eegfile,channel);
    
    eegfile=fopen(eegfname,'r','l'); % NOTE: the 'l' means that it came from a PC!
    if(eegfile==-1)
      eegfname=sprintf('%s%03i',events(e).eegfile,channel); % now try unpadded lead#
      eegfile=fopen(eegfname,'r','l');
    end
    if(eegfile==-1)
      eegfname=sprintf('%s.%i',events(e).eegfile,channel); % now try unpadded lead#
      eegfile=fopen(eegfname,'r','l');
    end
    
    % tell if not open
    if eegfile==-1
      % did not open
      error('ERROR: EEG File not found for event(%d): %s.\n',e,events(e).eegfile);
    end
    
    % read the eeg data
    thetime=offset+events(e).eegoffset-buffer;
    fseek(eegfile,nBytes*thetime,-1);
    
    
    readbytes=fread(eegfile,duration+(2*buffer),dataformat)';

    if length(readbytes)~=fix(duration+2*buffer)
      warning([eegfname ' only ' num2str(length(readbytes)) ' of ' num2str(size(EEG,2)) ' samples read for event ' num2str(e) ', appending zeros']);
      readbytes=[readbytes zeros(1,size(EEG,2)-length(readbytes))];
    end
    

    
    % close the file
    fclose(eegfile);
    
    % see if filter the data
    if length(filtfreq) > 0
      readbytes=buttfilt(readbytes,filtfreq,samplerate,filttype,filtorder);
    end
    % see if resample
    if resampledrate ~= samplerate
      % do the resample
      readbytes = resample(readbytes,round(resampledrate),round(samplerate));
      %readbytes = dsamp(readbytes,round(samplerate),round(resampledrate));
    end
    
    EEG(e,:)=readbytes;  
    
  end
  
  EEG = EEG(:,final_buffer+1:end-final_buffer);
  
  % apply the gain
  EEG = EEG.*gain;
end




