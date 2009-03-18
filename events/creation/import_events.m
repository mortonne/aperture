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
                        'event_filter', '');

fprintf('concatenating session events...')

% concatenate all sessions
subj_events = [];
for sess=subj.sess
  fprintf('%d ', sess.number)
  
  % load the events struct for this session
  sess_events_file = fullfile(sess.dir, params.events_file);
  s = load(sess_events_file);
  if ~isfield(s,'events')
    error('Variable named ''events'' not found in file:\n%s', sess_events_file)
  end
  events = s.events;

  % filter the events
  if ~isempty(params.event_filter)
    events = filterStruct(events, params.event_filter);
  end

  % fill in eeg fields if they are missing
  if ~isfield(events,'eegfile')
    [events(:).eegfile] = deal('');
    [events(:).eegoffset] = deal(NaN);
    [events(:).artifactMS] = deal(NaN);
  end

  % concatenate
  subj_events = [subj_events(:); events(:)]';
end
fprintf('\n')

% if no sessions had eeg fields, assume this is a behavioral experiment
if isempty(unique({events.eegfile}))
  events = rmfield(events, 'eegfile');
  events = rmfield(events, 'eegoffset');
  events = rmfield(events, 'artifactMS');
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
