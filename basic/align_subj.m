function align_subj(subj, sync_ext)
%ALIGN_SUBJ   Align a subject's events to EEG data.
%
%  align_subj(subj, sync_ext)
%
%  INPUTS:
%      subj:
%
%  sync_ext:
%
%  EXAMPLE:
%   subj.id = 'TJ003';
%   subj.sess.eegfile = '/data/eeg/TJ003/eeg.noreref/TJ003_18Feb09_1335';
%   align_subj(subj, '*.sync.txt');

for sess=subj.sess
  eegfiles = sess.eegfile;
  if ~iscell(eegfiles)
    eegfiles = {eegfiles};
  end
  sessdir = sess.dir;

  eventfile = fullfile(sessdir, 'events.mat');
  if ~exist(eventfile,'file')
    error('Events file not found: %s\n', eventfile)
  end
  
  % get sync files
  eegsyncfiles = cell(1,length(eegfiles));
  for i=1:length(eegfiles)
    [pathstr,basename] = fileparts(eegfiles{i});
    
    % get the EEG sync pulse file
    temp = dir(fullfile(pathstr, [basename sync_ext]));
    if length(temp)==0
      error('No EEG sync pulse files found that match: %s', ...
            fullfile(pathstr, [basename sync_ext]))
    elseif length(temp)>1
      error('Multiple EEG sync pulse files found that match: %s', ...
            fullfile(pathstr, [basename sync_ext]))
    end
    eegsyncfiles{i} = fullfile(pathstr, temp.name);
    
    % for runAlign, make eegfile point to a specific channel
    eegfiles{i} = [eegfiles{i} '.001'];
  end

  % there should be only one behavioral sync pulse file
  behsyncfile = fullfile(sessdir,'eeg.eeglog.up');
  if ~exist(behsyncfile,'file')
    % if we haven't already, extract the UP pulses
    raw_behsyncfile = fullfile(sessdir, 'eeg.eeglog');
    if ~exist(raw_behsyncfile,'file')
      error('Behavioral pulse file not found: %s\n', raw_behsyncfile)
    end
    fixEEGLog(raw_behsyncfile, behsyncfile);
  end
  
  % get the samplerate
  samplerate = eegparams('samplerate', fullfile(pathstr, [basename 'params.txt']));
  
  % run the alignment
  runAlign(samplerate,{behsyncfile},eegsyncfiles,eegfiles,{eventfile},'mstime',0,1);
end

function p=eegparams(field,paramfile)
%EEGPARAMS - Get a subject specific eeg parameter from the params.txt file.
% 
% If paramdir is not specified, the function looks in the 'docs/'
% directory for the params.txt file.
%
% The params.txt file can contain many types of parameters and will
% evaluate them as one per line.  These are examples:
%
% Channels 1:64
% samplerate 256
% subj 'BR015'
%
% FUNCTION:
%   p = eegparams(field,paramdir)
%
% INPUT ARGS:
%   field = 'samplerate';        % Field to retrieve
%   paramdir = '~/eeg/012/dat';  % Dir where to find params.txt
%
% OUTPUT ARGS:
%   p- the parameter, evaluated with eval()
%

% VERSION HISTORY:
%

switch field
  case 'samplerate'
  p = 256.03; % BioLogic standard
  case 'gain'
  p = 1; % BioLogic standard
  otherwise
  p = [];
end

% open the file
in = fopen(paramfile,'rt');
if in==-1
  return
end

% look for the parameter. If not found, return the
% default value
done = false;
while ~done
  f = fscanf(in,'%s',1);
  v = fgetl(in);
  if strcmp(f, field) % found it
    p = eval(v);
    done = true;
  elseif isempty(f) % nothing more to read
    done = true;
  end
end
fclose(in);
