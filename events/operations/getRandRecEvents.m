function rec_events = getRandRecEvents(events, params)
%GETRANDRECEVENTS   Get clean events from a free recall period
%
%  rec_events = getRandRecEvents(events, params)
%
%  INPUTS:
%   events:  an events structure with the following fields:
%             'session'
%             'trial'
%             'type'      - must include REC_START, REC_WORD
%             'itemno'
%             'intrusion'
%             'eegoffset'
%
%   params:  structure whose fields specify options for finding
%            recall events.  See below.
%
%  OUTPUTS:
%  rec_events:  a recall events structure.  Possible event types are:
%                REC_WORD    - correct recall
%                REP_WORD    - correct word repetition
%                RAND_WORD   - random epoch where there are no
%                              vocalizations
%                REC_WORD_VV - vocalization that was not a recall
%                              attempt
%                INT_WORD    - intrusion; can be a PLI or XLI
%
%  PARAMS:
%   recBuffer         - vocalization-free period in ms each recall 
%                       event must have in order to be included in
%                       rec_events. Default: 1000
%   recDuration       - assumed duration of each vocalization in ms.
%                       Default: 1000
%   recPeriodDuration - length of each recall period in ms. 
%                       Default: 90000
%   recWordField      - string that is in the beginning of the "type" 
%                       field of all recall events that involve 
%                       vocalizations
%   check             - if true, an image will be plotted showing the
%                       label of each sample in each recall period

% input checks
if ~exist('events','var') || ~isstruct(events)
  error('You must pass an events structure.')
end
if ~exist('params','var')
  params = struct;
end

params = structDefaults(params, ...
                        'recPeriodDuration', 90000, ...
                        'recDuration',       1000,  ...
                        'recBuffer',         1000,       ...
                        'recWordField',      'REC_WORD', ...
                        'check',             false);

check = params.check;
recWordField = params.recWordField;
if ~isfield(events,'list')
  listfield = 'trial';
else
  listfield = 'list';
end

% sanity checks!
types = unique({events.type});
if ~ismember('REC_START', types)
  error('No recall period start events (type=REC_START) found.')
elseif ~ismember(recWordField, types)
  warning('No word recall events (type=%s) found.', params.recWordField)
  rec_events = struct([]);
  return
end

% some defaults
samplerate = GetRateAndFormat(events(1));
recSamples = ms2samp(params.recPeriodDuration, samplerate);
voc_buffer = ms2samp(params.recBuffer, samplerate);
voc_duration = ms2samp(params.recDuration, samplerate);

% get all the word events
allWord_events = events(strmatch(recWordField, {events.type}));

% get start of each recall period
recStart_events = events(strcmp({events.type}, 'REC_START') & ...
                         ~isnan([events.(listfield)]));

% get session and list numbers; assuming each session has
% the same number of lists
sessions = [recStart_events.session];
lists = [recStart_events.(listfield)];

% events to fill
word_events = struct([]);
rand_events = struct([]);

% matrix to check results visually
scheck = [];

% loop over all session and lists
num_rec_events = 0;
num_bad_rec_events = 0;
for l = 1:length(lists)
  %fprintf('Session %d\tList %d\n', sessions(l), lists(l));

  % vector representing all samples in the recall period.
  % Free samples are true.
  samps = true(1,recSamples);
  
  % tsamp indicates the usage of each sample. codes are:
  %  not used         - 0
  %  recall events    - 0.5
  %  excluded samples - 1
  %  rand events      - 2
  % these values are used to set colors in the imagesc check at 
  % the end.
  tsamp = zeros(1,recSamples);

  % mark out the first buffersize worth so we are always after
  % start of recall
  samps(1:voc_buffer) = 0;

  % get the list events
  list_ind = [allWord_events.session]==sessions(l) & ...
             [allWord_events.(listfield)]==lists(l);
  if ~any(list_ind)
    fprintf('No recall events in session %d, trial %d. Skipping...', ...
            sessions(l), lists(l))
    continue
  end
  listEvents = allWord_events(list_ind);

  % correct the event offsets for start of recall
  recOffset = recStart_events(l).eegoffset;
  eventOffsets = [listEvents.eegoffset] - recOffset + 1;

  % mark off the buffer around each word
  lastEventIndex = 0;
  for e = 1:length(listEvents)
    if isempty(listEvents(e).eegfile)
      fprintf('Recall does not fall in recorded data!  Ignoring...\n');
      % ignore this and all future recalls in the list
      if e == 1
        samps(:) = 0;
        tsamp(:) = 1;
      else
        samps(eventOffsets(e-1):end) = 0;
        tsamp(eventOffsets(e-1):end) = 1;
      end
      break
    end

    % make sure it is from the same file as previous ones
    if e > 1 && ~strcmp(listEvents(e).eegfile, listEvents(e-1).eegfile)
      % different files, so ignore this and the rest
      samps(eventOffsets(e-1):end) = 0;
      tsamp(eventOffsets(e-1):end) = 1;
      fprintf('Recall split over two files!  Ignoring second file.\n');
      break
    end

    % set the start and end to mark:
    % [voc_buffer] | [voc_duration] [voc_buffer] (rand event can go here)
    mStart = eventOffsets(e) - voc_buffer + 1;
    mEnd = eventOffsets(e) + voc_duration + voc_buffer;

    % make sure it's within bounds
    mStart = max([mStart 1]);
    mEnd = min([recSamples mEnd]);

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
  newKeep = true(size(newEvents));
  for e = 2:lastEventIndex;
    % see the diff of onset of one to the next
    tdiff = eventOffsets(e) - eventOffsets(e-1);
    if tdiff < voc_duration + voc_buffer
      newKeep(e) = 0;
      %fprintf('Removed recall event. Onset difference: %g ms\n', ...
      %        tdiff * 1000 / samplerate);
    end
  end
  num_rec_events = num_rec_events + length(newKeep);
  num_bad_rec_events = num_bad_rec_events + nnz(~newKeep);
  
  newEvents = newEvents(newKeep);

  % append new words
  word_events = [word_events newEvents];

  % generate random events (try to get same number as real events)
  newRand_events = newEvents;
  newKeep = false(size(newEvents));
  for e = 1:length(newRand_events)
    % see what is available
    avail = find(samps);

    % make sure there are still ones avail
    if isempty(avail)
      fprintf('Warning: Only enough free space for %d random recalls.\n', ...
              e - 1);
      break
    end

    % get a random offset
    rsamp = randsample(avail, 1);

    % mark region as used
    mStart = rsamp - voc_buffer + 1;
    mStart = max([mStart 1]);

    samps(mStart:rsamp) = 0;
    tsamp(mStart:rsamp) = 2;

    % keep the event and set the proper event values
    newKeep(e) = 1;
    newRand_events(e).eegoffset = rsamp + recOffset - 1;
    newRand_events(e).type = 'RAND_WORD';
    newRand_events(e).item = '';
    newRand_events(e).itemno = NaN;
    newRand_events(e).rectime = NaN;
  end

  % append the new rand events
  newRand_events = newRand_events(newKeep);
  rand_events = [rand_events newRand_events];

  % append the tsamp for verification
  scheck = [scheck ; tsamp];
end
fprintf('Removed %d out of %d recall events.\n', ...
        num_bad_rec_events, num_rec_events)

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
allRec_events = replicateField(allRec_events,'type',recWordField);
allRep_events = replicateField(allRep_events,'type','REP_WORD');

% random searching events
allRand_events = rand_events;

% all vocalizations
VVind = inStruct(word_events,'strcmp(type,''REC_WORD_VV'') | strcmp(item,''!'')');
allVoc_events = replicateField(word_events(VVind),'type','VOC_WORD');

% all intrusions, ignoring vocalizations
allInt_events = replicateField(filterStruct(word_events(~VVind),'intrusion ~= -999 & intrusion ~= 0'),'type','INT_WORD');

rec_events = [allRec_events,allRand_events,allRep_events,allVoc_events,allInt_events];

if check
  imagesc(scheck)
end
