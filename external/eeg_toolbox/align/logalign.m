function [meddev,rawDevs]=logalign(beh_ms,eeg_offset,eeg_files,log_files,ms_field)
%LOGALIGN - Fit line to EEG sync and add files and offsets to logs.
%
% You provide matched EEG(offsets) and behavioral(ms) sync pulses
% and this function regresses a line for conversion from ms to eeg
% offsets.  Then it goes through each log file and appends the
% correct eeg file and offset into that file for each one.  You
% must specify a sample eeg file for each set of eeg offsets so
% that it can calculate the duration of each file.
%
% Note: Each logfile is backed up to logfile.old.
%
% Note2: The function can now append the eegfile and eegoffset to
% events structures passed in to the log_files cell array.  You
% must specify the field containing the ms data using the ms_field
% variable.
%
% FUNCTION:
%   logalign(beh_ms,eeg_offset,eeg_files,log_files)
%
% INPUT ARGS:
%   beh_ms = {ms};   % Cell array of beh_ms vectors
%   eeg_offset = {offset}; % Cell array of eeg sync offsets
%   eeg_files = {'/data/eeg/scalp/fr/500/eeg/dat/eeg0.022'};  %
%                           % Cell array of sample files for
%                           % matching each eeg_offset.
%   log_files = {'session0.log','events.mat'};  % Cell array of log files
%                                               % to process
%   ms_field = 'mstime';   % This is the default ms_field name
%

if ~exist('ms_field','var')
  ms_field = 'mstime';
end

b = zeros(2,length(eeg_offset));
eeg_start_ms = zeros(length(eeg_offset),1);
eeg_stop_ms = zeros(length(eeg_offset),1);

% loop over beh and eeg sync and get slopes
for f = 1:length(eeg_offset)
  x = beh_ms{f};
  y = eeg_offset{f};
  
  % get slope and offset for each eeg file
  xfix = x(1);
  [b(:,f), bint, r, rin, stats] = regress(y, [ones(size(x)) x - xfix]);
  b(1,f) = b(1,f) - xfix * b(2,f);
  
  % calc max deviation
  yhat = [ones(size(x)) x] * b(:,f);
  maxdev = max(abs(yhat - y));
  meddev{f} = median(abs(yhat - y));
  rawDevs{f} = yhat - y;
  
  % calc the start and end for that file
  % make a fake event to load data fromg gete
  [path,efile,ext] = fileparts(eeg_files{f});
  fileroot{f} = fullfile(path,efile);
  fileonly{f} = efile;
  chan = str2num(ext(2:end));
  event = struct('eegfile',fileroot{f});
  eeg = gete(chan,event,0);
  duration = length(eeg{1});
  
  % get start and stop in ms
  eeg_start_ms(f) = round((1 - b(1,f))/b(2,f));
  eeg_stop_ms(f) = round((duration - b(1,f))/b(2,f));
  
  % standard error of prediction, to bounds of the EEG file
  sxx = sum((x - mean(x)) .^ 2);
  sd = std(y);
  x_star = [eeg_start_ms(f) eeg_stop_ms(f)];
  sepred = sd * sqrt(1 + 1 / length(x) + (x_star - mean(x)).^2 / sxx);

  % report stats
  fprintf('%s:\n',eeg_files{f});
  fprintf('\tMax. Dev. = %f ms\n', maxdev);
  fprintf('\tMedian. Dev. = %f ms\n', meddev{f});  
  fprintf('\t95th pctile. = %f ms\n', prctile(rawDevs{f},95)); 
  fprintf('\t99th pctile. = %f ms\n', prctile(rawDevs{f},99));
  %fprintf('\tMax pred. err. = %f\n', max(sepred));
  fprintf('\tR^2 = %f\n', stats(1));
  fprintf('\tSlope = %f\n', b(2,f));
  fprintf('\tPulse range = %.3f minutes\n',range(x)/1000/60);
end

% loop over log files
for f = 1:length(log_files)

 % see if is logfile or events structure
  if strfound(log_files{f},'.mat')
    % is events struct
    dostruct = 1;
    
    events = loadEvents(log_files{f});

    % save a backup of the file
    try
      % this fails with the permissions setup on rhino:
      copyfile(log_files{f},[log_files{f} '.old'],'f');
      catch
      % calling unix directly works    
      unix(sprintf('cp %s %s.old', log_files{f}, log_files{f}));
    end
    
    % get the ms field from the struct
    ms = getStructField(events,ms_field);
    
  else
    % is a text logfile
    dostruct = 0;
    
    % load the file
    [ms,therest] = textread(log_files{f},'%n%[^\n]','delimiter','\t');
  
    % save a backup of the file
    copyfile(log_files{f},[log_files{f} '.old'],'f');
  
    % open the new file
    fid = fopen(log_files{f},'w');
  end
  
  % loop over each line
  for l = 1:length(ms)
    % figure out which eeg it's in
    ef = intersect(find(ms(l)>=eeg_start_ms),find(ms(l)<=eeg_stop_ms));
    
    if isempty(ef)
      if dostruct
        fprintf('WARNING - No EEG data for event at %ld ms.\n', ms(l));
        % add in a blank eegfile and offset
        events(l).eegfile = '';
        events(l).eegoffset = 0;
      else
        fprintf('WARNING - Out of bounds of eeg files:\n\t%ld\t%s\n',ms(l),therest{l});
      end
      
      continue
    end
    
    % calc the beh_offsets
    beh_offset = round(ms(l)*b(2,ef) + b(1,ef));
      
    if dostruct
      % append the fields
      %events(l).eegfile = fileonly{ef};
      events(l).eegfile = fileroot{ef};
      events(l).eegoffset = beh_offset;
    else
      % write it to file
      %fprintf(fid,'%s\t%s\t%s\t%ld\n',num2str(ms(l),16),therest{l},fileonly{ef},beh_offset);
      fprintf(fid,'%s\t%s\t%s\t%ld\n',num2str(ms(l),16),therest{l},fileroot{ef},beh_offset);
    end
  end

  if dostruct
    % save the new events
    saveEvents(events,log_files{f});
  else
    % close the file
    fclose(fid);
  end
end



