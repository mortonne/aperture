function exp = addEvents(exp, eventsFile, eventFilter, evname, resDir)
%ADDEVENTS   Import events into an exp struct.
%   EXP = ADDEVENTS(EXP) loads the events saved in each session
%   directory in a file named 'events.mat', and concatenates
%   them to create one events struct for each subject.  Each
%   subject in EXP has a new ev object added named 'events'.
%
%   ADDEVENTS prepares each subject's events for analysis in
%   other scripts in eeg_ana.
%
%   EXP = ADDEVENTS(EXP,EVENTSFILE,EVNAME,RESDIR) loads the
%   events in each session directory using the relative path
%   EVENTSFILE, saves in RESDIR/events, and names the new ev
%   object EVNAME.
%

if ~exist('evname', 'var')
  evname = 'events';
end
if ~exist('resDir', 'var')
  resDir = exp.resDir;
end
if ~exist(fullfile(resDir, 'events'), 'dir')
  mkdir(fullfile(resDir, 'events'));
end
if ~exist('eventFilter','var')
  eventFilter = '';
end
if ~exist('eventsFile', 'var')
  eventsFile = 'events.mat';
end

fprintf('Concatenating session events...\n')
for subj=exp.subj
  fprintf('%s:\t', subj.id);
  
  % concatenate all sessions
  subj_events = [];
  for sess=subj.sess
    fprintf('%d\t', sess.number)
    % load the events struct for this session
    load(fullfile(sess.dir, eventsFile));
    
    if ~isempty(eventFilter)
      events = filterStruct(events,eventFilter);
    end
    
    % fill in eeg fields if they are missing
    if ~isfield(events, 'eegfile')
      [events(:).eegfile] = deal('');
      [events(:).eegoffset] = deal(NaN);
      [events(:).artifactMS] = deal(NaN);
    end
    
    subj_events = [subj_events(:); events(:)]';
  end

  % if no sessions had eeg fields, assume this is a behavioral experiment
  if isempty(unique(getStructField(events, 'eegfile')))
    events = rmfield(events, 'eegfile');
    events = rmfield(events, 'eegoffset');
    events = rmfield(events, 'artifactMS');
  end
  events = subj_events;

  % create an ev object to hold metadata
  evfile = fullfile(resDir, 'events', [evname '_' subj.id '.mat']);
  ev = init_ev(evname,subj.id,evfile,length(events));

  % save the new events
  save(ev.file, 'events');

  % add the ev object to subj, put the new subj in exp
  subj = setobj(subj,'ev',ev);
  exp = setobj(exp,'subj',subj);
  
  fprintf('\n')
end

% update!
exp = update_exp(exp);
