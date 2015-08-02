function basename = egi_split(egifile,subject,basedir)
%EGI_SPLIT - Process a simple raw file exported from EGI
%
% This function reads in a raw file from EGI and splits it into
% separate channel files for use in the eeg_toolbox.  It saves the
% data in raw form supplying the gain factor used by the toolbox to
% convert the raw data to uV.
% 
% The resulting channel files will follow the standard naming
% format of the subject, date, and time of the start of recording.
%
% Any events in the EGI file will be saved to a separate file
% (usually with a .DIN extension).  The events file will contain an
% the time (in samples) when each event occured.  You can use this
% file to align with your exprimental events.
%
% FUNCTION:
%   egi_split(egifile,subject,basedir)
%
% INPUT ARGS:
%   egifile = '001 20040624 13.33.ref.fil.raw';  % file from EGI
%   subject = 'FR001';                           % Subject id
%   basedir = '/data/eeg/FR001/eeg.reref';       % Dir. to put
%                                                %  split out 
%                                                %  channel files
% OUTPUT ARGS:
%   basename - The basename determined from the subject and file.
%

%
% 2004/7/6 - PBS - Events now write out as int8 binary.
%

% input checks
if ~exist('egifile','var')
  error('You must pass the path to an EEG raw file.')
elseif ~exist('subject','var')
  error('You must supply a subject ID.');
end
if ~exist('basedir','var')
  basedir = '.';
end

% months
month = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};

% ampinfo
ampinfo = [-32767 32767; -2.5 2.5];
ampfact = 1000;
ampgain = calcGain(ampinfo,ampfact);
outputformat = 'short';

% open the file
fid = fopen(egifile,'r','b');

% load the header info
egi_version = fread(fid,1,'long');
egi_year = fread(fid,1,'short');
egi_month = fread(fid,1,'short');
egi_day = fread(fid,1,'short');
egi_hour = fread(fid,1,'short');
egi_minute = fread(fid,1,'short');
egi_second = fread(fid,1,'short');
egi_msec = fread(fid,1,'long');
egi_rate = fread(fid,1,'short');
egi_channels = fread(fid,1,'short');
egi_gain = fread(fid,1,'short');
egi_bits = fread(fid,1,'short');
egi_range = fread(fid,1,'short');
egi_samples = fread(fid,1,'long');
egi_events = fread(fid,1,'short');
egi_event_codes = cell(egi_events,1);
for e = 1:egi_events
  egi_event_codes{e} = deblank(char(fread(fid,4,'char')'));
end

% set the read format
switch egi_version
 case 2
  format = 'short';
 case 4
  format = 'single';
 case 8
  format = 'double';
 otherwise
  disp('Unknown EGI format.')
  fclose(fid)
  return
end

% generate a filename
year = num2str(egi_year);
basename = [subject '_' num2str(egi_day) month{egi_month} year(3:4) '_' num2str(egi_hour,'%02d') num2str(egi_minute,'%02d')];

% Give them some file info
fprintf('EEG File Information:\n')
fprintf('---------------------\n')
fprintf('Sample Rate = %d\n', egi_rate);
fprintf('Start of recording = %d/%d/%d %02d:%02d\n',egi_month,egi_day,egi_year,egi_hour,egi_minute);
fprintf('Number of Channels = %d\n', egi_channels);
fprintf('Number of Events = %d\n', egi_events);
fprintf('Base Name = %s\n', basename);
fprintf('\n');


% load the entire rest of the file
totalsamps = (egi_channels+egi_events)*egi_samples;

% status
fprintf('Loading %d samples',totalsamps);

% loop to load from file so it takes less memory
stepsize = 1000000;
totalread = 0;
raw = int16(zeros(totalsamps,1));
while totalread < totalsamps
  sampsleft = totalsamps - totalread;
  if sampsleft < stepsize
    toread = sampsleft;
  else
    toread = stepsize;
  end
  fprintf('.');
  dat = int16(fread(fid,toread,format)./ampgain);
  if length(dat)<toread
    to_add = toread - length(dat);
    warning('Read only %ld samples out of an expected %ld. Prepending %d NaNs...', ...
            totalread + length(dat), totalsamps, to_add)
    dat = [NaN(to_add,1); dat];
  end
  raw(totalread+1:totalread+toread) = dat;
  totalread = totalread + toread;
end
fprintf('Done.\n');

% reshape for processing
raw = reshape(raw,egi_channels+egi_events,egi_samples);

% close the main file
fclose(fid);

fprintf('Processing %d channels and events',size(raw,1));

%check whether basedir exists, if not, create it
if ~exist(basedir,'dir')
  mkdir(basedir)
end

% loop over channels and write to files
% open all the chan files
for c = 1:egi_channels
  fprintf('.');
  fid = fopen(fullfile(basedir,[basename '.' num2str(c,'%03d')]),'wb','l');
  fwrite(fid,raw(c,:),outputformat);
  fclose(fid);
end

% add the event info
cur_event = 0;
for e = egi_channels+1:egi_channels+egi_events
  fprintf('.');
  cur_event = cur_event + 1;
  fid = fopen(fullfile(basedir,[basename '.' egi_event_codes{cur_event}]),'wb','l');
  fwrite(fid,raw(e,:),'int8');
  fclose(fid);
end

fprintf('Done.\n');

% write out params.txt file
paramfile = fullfile(basedir,'params.txt');
fid = fopen(paramfile,'w');
fprintf(fid,'samplerate %d\ndataformat ''%s''\ngain %g\n',egi_rate,outputformat,ampgain);
fclose(fid);
           

% write out new params.txt file
paramfile = fullfile(basedir,[basename '.params.txt']);
fid = fopen(paramfile,'w');
fprintf(fid,'samplerate %d\ndataformat ''%s''\ngain %g\n',egi_rate,outputformat,ampgain);
fclose(fid);
