function subj = import_events(subj,res_dir,ev_name,params)
%IMPORT_EVENTS   Import events information for a subject.
%
%  subj = import_events(subj, res_dir, ev_name, params)
%
%  Use this function to import events information for a subject.
%  It concatenates events for all sessions of a subject, saves
%  them, and creates an ev object to hold metadata about the
%  events.
%
%  INPUTS:
%     subj:  a subject structure.
%
%  res_dir:  path to the directory where results will be saved.
%            An events structure will be saved in:
%             [res_dir]/events
%
%  ev_name:  string identifier for the created ev object.
%            default: 'events'
%
%   params:  structure that sets options for importing events.
%            See below.
%
%  OUTPUTS:
%     subj:  subject structure with an added ev object.
%
%  PARAMS:
%  events_file  - path (relative to each session directory in
%                 subj) to the MAT-file where each events
%                 structure to be imported is saved.
%                 default: 'events.mat'
%  event_filter - string to be passed into filterStruct to
%                 filter the events structure before it is
%                 imported. default: '' (no filtering)
%
%  See also create_events.

% input checks
if ~exist('subj','var')
  error('You must pass a subject structure.')
  elseif ~exist('res_dir','var')
  error('You must pass the path to the results directory.')
end
if ~exist('ev_name','var')
  ev_name = 'events';
end
if ~exist('params','var')
  params = [];
end

% default parameters
params = structDefaults(params, ...
                        'events_file',  'events.mat', ...
                        'event_filter', '',           ...
                        'check_eeg',    false);

if length(subj.sess)>1
  fprintf('concatenating session events...')
end

% concatenate all sessions
subj_events = [];
for sess=subj.sess
  if length(subj.sess)>1
    fprintf('%d ', sess.number)
  end
  
  % load the events struct for this session
  sess_events_file = fullfile(sess.dir, params.events_file);
  if ~exist(sess_events_file, 'file')
    warning('eeg_ana:import_events:missingEventsFile', ...
            'events file not found: %s\n', sess_events_file)
    continue
  end

  s = load(sess_events_file, 'events');
  events = s.events;

  % fill in eeg fields if they are missing
  if params.check_eeg && ( ~isfield(events,'eegfile') || all(cellfun(@isempty,{events.eegfile})) )
    try
      % try to fix it one more time;
      % force alignment to run again
      prep_egi_data2(subj.id, sess.dir, ...
                     'eventfiles', {sess_events_file}, ...
                     'steps_to_run', {'align'});
      
      % it must have worked! load the new events
      s = load(sess_events_file, 'events');
      events = s.events;
    catch err
      % We failed. Possible causes:
      % 1. This isn't EGI data; we wouldn't expect prep_egi_data to work.
      % 2. None of the events aligned, and runAlign crashed without saving
      %    a new events structure with an "eegfile" field.
      % 3. There is something wrong with the .raw file.
      % 4. Unexpected changes to eeg_toolbox functions.

      % give up on alignment and artifact detection. Put in some dummy fields
      % so we can keep going. When doing EEG analyses, remember to filter out 
      % events with an empty eegfile.
      warning('eeg_ana:import_events:failedAlign', ...
              'Failed alignment of: %s.\nError thrown by prep_egi_data:\n%s', ...
              sess.dir, getReport(err))

      [events(:).eegfile] = deal('');
      [events(:).eegoffset] = deal(NaN);
      [events(:).artifactMS] = deal(NaN);
    end
  end

  % filter the events
  if ~isempty(params.event_filter)
    events = filterStruct(events, params.event_filter);
  end

  % concatenate
  subj_events = [subj_events(:); events(:)]';
end
if length(subj.sess)>1
  fprintf('\n')
end

events = subj_events;

% save the new events
ev_dir = fullfile(res_dir, 'events');
if ~exist(ev_dir,'dir')
  mkdir(ev_dir)
end
ev_file = fullfile(ev_dir, sprintf('%s_%s.mat', ev_name, subj.id));
save(ev_file, 'events')

% create a new ev object
ev = init_ev(ev_name, subj.id, ev_file, length(events));
fprintf('ev object "%s" created.\n', ev_name)

% add the ev object to subj
subj = setobj(subj, 'ev', ev);
