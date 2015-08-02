function runAlign(samplerate,beh_file,eeg_file,chan_files,log_files,ms_field,isfrei,isegi,moreAccurateAlign)
%RUNALIGN - Wrapper for the pulsealign and logalign functions.
%
% This is a relatively specialized wrapper for the EEG toolbox
% alignment functions.  You provide a list of behavioral sync pulse
% files, a list of eeg sync pulse files, a list of matching eeg
% channel files, and a list of log files or files containg events
% structures to process.
%
% This function will modify the files passed into the log_files
% parameters, saving original copies.
%
% FUNCTION:
%   runAlign(samplerate,beh_file,eeg_file,chan_files,log_files,isfrei)
%
% INPUT ARGS:
%   samplerate = 500;
%   beh_file = {'behfile1','behfile2'};
%   eeg_file = {'eegfile1','eegfile2'};
%   chan_files = {'/data/eeg/file1.001','/data/eeg/file2.001'};
%   log_files = {'events.mat'};
%   ms_field = 'mstime';
%   isfrei = 0;       % Read in freiburg format
%   isegi = 0;  %data is EGI formatted
%   moreAccurateAlign = 1; %use fancy alignment script (more accurate, but
%                           slower)

if ~exist('ms_field','var')
  ms_field = 'mstime';
end
if ~exist('isfrei','var')
  isfrei = 0;
end
if ~exist('isegi','var')
  isegi = 0;
end
if ~exist('moreAccurateAlign','var')
  moreAccurateAlign = 0;
end

threshMS = 10;
window = 100;

% load in the beh_ms and the pulses
beh_ms = [];
for f = 1:length(beh_file) 
  % read in free recall data
  beh_ms = [beh_ms; textread(beh_file{f},'%n%*[^\n]','delimiter','\t')];
end

% sort it
beh_ms = sort(beh_ms);

% loop over pulses and run pulsealign to get sets of matched inputs
eeg_match = cell(1, length(eeg_file));
beh_match = cell(1, length(eeg_file));
for f = 1:length(eeg_file)
  % load eeg pulses
  if isfrei
    [s, pulse_str] = system(['grep -i SYNC1 ' eeg_file{f} ' | cut -d, -f 1']);
    pulses = strread(pulse_str,'%u');
  elseif isegi
    % open DIN file 
    eegsyncID = fopen(eeg_file{f});
    eegsync = fread(eegsyncID, inf, 'int8');
    fclose(eegsyncID);
    pulses = find(eegsync>0);
  else
    [s,pulse_str] = system(['cut -f 1 ' eeg_file{f}]);
    pulses = strread(pulse_str,'%u');
  end

  pulse_ms = pulses*1000/samplerate;

  % remove all pulses under 100ms (Part of Start and End pulses)
  dp = diff(pulse_ms);
  yp = find(dp < 100);
  pulse_ms(yp+1) = [];
  pulses(yp+1) = [];

  % run pulsealign
  mywin = min(round(length(pulses)/2), window);
  if mywin < 5
    mywin = 5;
  end

  if moreAccurateAlign
    [beh_match{f}, eeg_match{f}] = pulsealign2(beh_ms, pulses);
    method = 2;
  else
    [beh_match{f}, eeg_match{f}] = pulsealign(beh_ms, pulses, samplerate, ...
                                              threshMS, mywin);
    method = 1;
  end
  fprintf('file %d, alignment method %d: %d matches of %d recorded pulses\n', ...
          f, method, length(beh_match{f}), length(pulses));
end

[a, err] = logalign(beh_match, eeg_match, chan_files, log_files, ms_field);

