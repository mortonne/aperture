function events = addArtifacts(eventfile,channels,thresh,plotit,replace_eegfile)
%ADDARTIFACTS - Add artifact info to events structure.
%
% This function loads an events structure, loops over the unique
% files in the events structure, loads the EEG data from each
% channel in each file, makes the channel data bipolar if
% necessary, finds the blink events for each channel, performs a
% logical OR of the blinks across channels, populates the event
% structure structure with the millisecond time of the first blink
% in each event, then saves the events structure back to file.
%
% In case you need to do more detailed processing of artifact times,
% this function saves the indexes of each artifact to the file
% eegfile_blink.mat for each unique eegfile in the events structure.
% You can load this file with the loadVar function. 
%
% FUNCTION: 
%   events = addArtifacts(eventfile,channels,thresh,plotit)
%
% INPUT ARGS:
%   eventfile = 'beh/events.mat';  % Events struct to process
%   channels = {1,2,[63,64]};      % Cell array of channels to
%                                  %  search for eye blinks. Two
%                                  %  element arrays of channels will
%                                  %  have the diff taken before
%                                  %  processing for blinks.
%   thresh = [50,20,50];           % Thresh in uV for each channel
%                                  %  If one value present, will
%                                  %  use for all.
%   plotit = 0;                    % 1 or 0 to plot the signal, signal
%                                  %  distribution, and eyeblinks
%                                  %  for determining a better thresh
%
% OUTPUT ARGS:
%   events - Returns the new events structure that it wrote to file.

% input checks
if ~exist('eventfile','var') || isempty(eventfile)
  error('You must pass an eventfile.')
elseif ~exist('channels','var')
  error('You must indicate which channels to use.')
elseif max(cellfun(@length, channels))>2
  error('Each cell of channels may not contain more than two elements.')
end
if ~exist('thresh','var')
  thresh = 100;
end
if length(thresh) < length(channels)
  if length(thresh)>1
    error('thresh must be of length 1 or the same length as the number of channels.')
  end
  thresh = repmat(thresh, 1, length(channels));
end
if ~exist('plotit','var')
  plotit = 0;
end
if ~exist('replace_eegfile','var')
  replace_eegfile = [];
end

% see if we are processing a single file
if ~strcmp(eventfile(end-3:end),'.mat')
  % make fake events
  events = struct('eegfile',{eventfile},'eegoffset',{1});
  
  % get the fnames
  fnames = {eventfile};
  
  % dont process events
  processEvents = 0;
else
  % load the events
  events = loadEvents(eventfile,replace_eegfile);

  % save a backup
  backupfile = [eventfile '.old'];
  saveEvents(events,backupfile);
  fprintf('Saved backup to %s\n',backupfile);

  % get the unique file names that are not empty
  fnames = unique({events.eegfile});
  fnames = fnames(~cellfun(@isempty, fnames));
  if isempty(fnames)
    error('eeg_toolbox:addArtifacts:NoEEGFile', ...
          'no EEG files for events: %s\n', eventfile)
  end

  % process events
  processEvents = 1;
end

% get data info for the first file
samplerate = GetRateAndFormat(fileparts(fnames{1}));

% allocate space for blink index
blinks = cell(1,length(fnames));

n = 1;
for i=1:length(fnames)
  % make a fake events structure for this file
  temp_events = struct('eegfile', fnames{i}, 'eegoffset', 1);
  art_mask = [];
  
  for j=1:length(channels)
    fprintf('Loading channel data: ');
    chan_numbers = channels{j};

    % get EEG for this channel, file
    if length(chan_numbers)==2
      % load a bipolar channel
      fprintf('%d %d\n', chan_numbers(1), chan_numbers(2))
      eeg1 = gete(chan_numbers(1),temp_events,0,0,0,[]);
      eeg2 = gete(chan_numbers(2),temp_events,0,0,0,[]);
      eeg = eeg1{1} - eeg2{1};
    else
      % load a single channel
      fprintf('%d\n', chan_numbers)
      eeg = gete(chan_numbers,temp_events,0,0,0,[]);
      eeg = eeg{1};
    end
    
    % find artifacts
    fprintf('Searching for blinks using thresh=%guV...\n',thresh(j));
    art_mask = [art_mask; findBlinks(eeg, thresh(j))];
    
    if plotit
      subplot(length(fnames), length(channels), n)
      plot_artifacts(eeg, art_mask);
      title(['File: ' fnames{i} ', channels: ' num2str(chan_numbers)])
      drawnow
    end
    n = n + 1;
  end
  % if a given sample was bad for any channel, mark it
  blinks{i} = find(any(art_mask,1));
end

% see if we have events to process
if ~processEvents
  % return the blinks and do no more
  events = blinks{1};
  return
end

% write out blink indexes
for i = 1:length(blinks)
  blinkfile = [fnames{i} '_blinks.mat'];
  saveVar(blinks{i},blinkfile);
end

% now we have the blink indexes, loop over events
fprintf('Adding artifacts to events...\n');
for e = 1:length(events)
  % make sure the event has an eegfile
  if isempty(events(e).eegfile)
    % no file, so skip it adding the field with no blink
    events(e).artifactMS = -1;
    continue
  end
  
  % see which file we are in
  i = find(strcmp(events(e).eegfile, fnames));

  % look for blink
  if e+1 < length(events)
    % can use next event as upper bound
    ev_blink = blinks{i}(blinks{i}>=events(e).eegoffset & blinks{i} < events(e+1).eegoffset);
  else
    % no upper bound
    ev_blink = blinks{i}(blinks{i}>=events(e).eegoffset);
  end
  
  % if have blink, convert first one to ms
  if ~isempty(ev_blink)
    % add in the first one
    blinkOffset = (ev_blink(1) - events(e).eegoffset);
    blinkMS = blinkOffset*1000/samplerate;
    events(e).artifactMS = blinkMS;
  else
    % no blink
    events(e).artifactMS = -1;
  end
  
end

% save the updated events
saveEvents(events,eventfile);
fprintf('Saved updated events to %s.\n',eventfile);

function plot_artifacts(eeg, artifacts)
  plot(eeg)
    
  if any(artifacts)
    hold on
    plot(find(artifacts), max(eeg)/2, 'r.')
    hold off
  end

  % get the max of each window
  %ex_beeg = extend(beeg{i},window);
  %ex_beeg = reshape(ex_beeg,round(length(ex_beeg)/window),window);
  %winmax = squeeze(max(abs(ex_beeg),[],2)-mean(ex_beeg,2));
  %[in,winmax] = local_max(abs(fast{i}));
  %hist(winmax,500);
%endfunction
