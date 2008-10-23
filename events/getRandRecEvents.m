function allRetEvents = getRandRecEvents(events,samplerate,bufferMS,check)
%GETRANDRECEVENTS - Get important events from FR retrieval period
%
% Assumptions:
%   - REC_START and REC_WORD events
%   - 90 second recall period
% 
% FUNCTION:
%   allRetEvents = getRandRecEvents(events,samplerate,bufferMS,check)
%
% Possible event types:
%   REC_WORD - Correct recall (only first recall per list).
%   REP_WORD - Correct word repetition.
%   RAND_WORD - Random epochs when nothing else is happening.
%   VOC_WORD - Non-recall-related vocalization.
%   INT_WORD - Recall intrusion.

if ~exist('check','var')
  check = 0;
end

if ~isfield(events,'list')
  listfield = 'trial';
  else
  listfield = 'list';
end

% sanity checks!
types = unique({events.type});
if ~ismember('REC_START',types)
  error('No recall period start events (type=REC_START) found.')
elseif ~ismember('REC_WORD',types)
  error('No word recall events (type=REC_WORD) found.')
end

% some defaults
recTime = 90000;
recSamples = floor(recTime * samplerate/1000);
bufferSamp = floor(bufferMS*samplerate/1000);

% get all the word events
allWord_events = filterStruct(events,'strfound(type,''REC_WORD'')');

% get start of each recall period
recStart = inStruct(events,'strcmp(type,''REC_START'')');
recStart = [logical(0) recStart(1:end-1)];
recStart_events = events(recStart);
lists = getStructField(recStart_events,listfield);
sessions = getStructField(recStart_events,'session');

length(lists)

% events to fill
word_events = struct([]);
rand_events = struct([]);

% matrix to check results visually
scheck = [];

% loop over all session and lists
for l = 1:length(lists)
  fprintf('Session %d\tList %d\n',sessions(l),lists(l));

  % clean out the possible start setting to all possible
  samps = ones(1,recSamples);   % 1 if free
  tsamp = zeros(1,recSamples);  % if and how a sample is used

  % mark out the first buffersize worth so we are always after
  % start of recall
  samps(1:bufferSamp) = 0;

  % get the list events
  listEvents = filterStruct(allWord_events,sprintf('%s==%d & session==%d', listfield, lists(l), sessions(l)));
  %  listEvents = filterStruct(allWord_events,'list == varargin{1} & session == varargin{2}',lists(l),sessions(l));
  if length(listEvents) == 0
    % no events for list
    continue;
  end

  % correct the event offsets for start of recall
  recOffset = recStart_events(l).eegoffset;
  eventOffsets = getStructField(listEvents,'eegoffset')-recOffset + 1;

  % mark off the buffer around each word
  lastEventIndex = 0;
  for e = 1:length(listEvents)
    if strcmp(listEvents(e).eegfile,'')
      % no in recorded data
      fprintf('Recall does not fall in recorded data!  Ignoring...\n');

      % ignore this and all future recalls in the list
      if e == 1
        samps(:) = 0;
        tsamp(:) = 1;
        else
        samps(eventOffsets(e-1):end) = 0;
        tsamp(eventOffsets(e-1):end) = 1;
      end

      % don't process any more of the events for this list
      break;
    end

    % make sure it is from the same file as previous ones
    if e > 1 & ~strcmp(listEvents(e).eegfile,listEvents(e-1).eegfile)
      % different files, so ignore this and the rest
      samps(eventOffsets(e-1):end) = 0;
      tsamp(eventOffsets(e-1):end) = 1;
      fprintf('Recall split over two files!  Ignoring second file.\n');

      break;
    end

    % set the start and end to mark
    mStart = eventOffsets(e) - bufferSamp + 1;
    mEnd = eventOffsets(e) + (2*bufferSamp);

    % make sure it's within bounds
    if mStart < 1
      mStart = 1;
    end
    if mEnd > recSamples
      mEnd = recSamples;
    end

    % mark the range as used
    samps(mStart:mEnd) = 0;
    tsamp(mStart:mEnd) = .5;

    % if this is the last word event, then don't allow any space
    % after it
    if e == length(listEvents)
      % mark as used
      samps(eventOffsets(e):end) = 0;
      tsamp(eventOffsets(e):end) = 1;      
    end

    % save the last event index so we know how many events are included
    lastEventIndex = e;
  end  

  % append all non-overlapping events
  newEvents = listEvents(1:lastEventIndex);
  newKeep = logical(ones(length(newEvents),1));
  for e = 2:lastEventIndex;
    % see the diff of onset of one to the next
    tdiff = eventOffsets(e) - eventOffsets(e-1) - 2*bufferSamp;
    if tdiff < 0
      newKeep(e) = 0;
      fprintf('Removed recall event: %g ms\n',tdiff*1000/samplerate);
    end
  end
  newEvents = newEvents(newKeep);

  % append new words
  word_events = [word_events newEvents];

  % generate random events (try to get same number as real events)
  newRand_events = newEvents;
  newKeep = logical(zeros(length(newEvents),1));
  for e = 1:length(newRand_events)
    % see what is available
    avail = find(samps);

    % make sure there are still ones avail
    if length(avail) == 0
      % problem
      fprintf('ERROR: Not enough free space for random recalls.\n');
      break;
    end

    % get random index
    rind = randperm(length(avail));

    % pick the offset
    rsamp = avail(rind(1));

    % mark region as used
    mStart = rsamp - bufferSamp + 1;
    if mStart < 1
      mStart = 1;
    end
    samps(mStart:rsamp) = 0;
    tsamp(mStart:rsamp) = 2;

    % keep the event and set the proper event values
    newKeep(e) = 1;
    newRand_events(e).eegoffset = rsamp + recOffset - 1;
    newRand_events(e).type = 'RAND_WORD';
    newRand_events(e).item = '';
    newRand_events(e).itemno = -999;
    newRand_events(e).rectime = -999;
  end

  % append the new rand events
  newRand_events = newRand_events(newKeep);
  rand_events = [rand_events newRand_events];

  % append the tsamp for verification
  scheck = [scheck ; tsamp];
end


% categorize events

% correct recalls and correct repetitions
allRec_events = [];
allRep_events = [];
for e = 1:length(word_events)
  % see if is a correct recall
  if word_events(e).intrusion==0
    % is correct, so see if is repetition
    filtstr = sprintf('itemno==%d & session==%d & %s==%d', word_events(e).itemno, word_events(e).session, listfield, word_events(e).(listfield));
    if e>1 & any(inStruct( word_events(1:(e-1)), filtstr ))
      %    if e>1 & sum(inStruct(word_events(1:(e-1)),'itemno==varargin{1} & session==varargin{2} & list==varargin{3}',word_events(e).itemno, word_events(e).session, word_events(e).list))>0
      % is a repeat in the current list
      allRep_events = [allRep_events word_events(e)];
      else
      % is first correct recall of that item in the list
      allRec_events = [allRec_events word_events(e)];
    end      
  end
end
allRec_events = replicateField(allRec_events,'type','REC_WORD');
allRep_events = replicateField(allRep_events,'type','REP_WORD');

% random searching events
allRand_events = rand_events;

% all vocalizations
VVind = inStruct(word_events,'strcmp(type,''REC_WORD_VV'') | strcmp(item,''!'')');
allVoc_events = replicateField(word_events(VVind),'type','VOC_WORD');

% all intrusions, ignoring vocalizations
allInt_events = replicateField(filterStruct(word_events(~VVind),'intrusion ~= -999 & intrusion ~= 0'),'type','INT_WORD');

allRetEvents = [allRec_events,allRand_events,allRep_events,allVoc_events,allInt_events];

if check
  imagesc(scheck);colorbar
end
