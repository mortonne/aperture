function subj = import_events(subj, ev_name, res_dir, varargin)
%IMPORT_EVENTS   Import events information for a subject.
%
%  Use this function to import events information for a subject. It
%  concatenates events for all sessions of a subject, saves them, and
%  creates an ev object to hold metadata about the events.
%
%  subj = import_events(subj, ev_name, res_dir, ...)
%
%  INPUTS:
%     subj:  a subject structure.
%
%  ev_name:  string identifier for the created ev object.
%
%  res_dir:  path to the directory to save results. The events structure
%            will be saved in [res_dir]/events.
%
%  OUTPUTS:
%     subj:  subject structure with an added ev object.
%
%  PARAMS:
%  May be specified either using a structure or parameter, value pairs.
%  Defaults are shown in parentheses.
%   events_file  - path (relative to each session directory in subj) to
%                  the MAT-file where each events structure to be
%                  imported is saved. ('events.mat')
%   sess_filter  - string to be passed into inStruct to determine which
%                  sessions to include. ('')
%   event_filter - string to be passed into filterStruct to filter the
%                  events structure before it is imported. ('')
%   check_eeg    - if true, a check will be run on the eegfile field of
%                  each events structure; if the eegfile field is
%                  missing, prep_egi_data will be run on the session
%                  in an attempt to align the events. (false)
%
%  See also create_events.

% input checks
if ~exist('subj', 'var')
  error('You must pass a subject structure.')
elseif length(subj) > 1
  error(['May only pass one subject. Use apply_to_subj to process ' ...
         'multiple subjects.'])
elseif ~exist('res_dir', 'var')
  error('You must pass the path to the results directory.')
elseif ~exist('ev_name', 'var')
  error('You must specify a name for the events object.')
end

% process options
defaults.events_file = 'events.mat';
defaults.sess_filter = '';
defaults.event_filter = '';
defaults.check_eeg = false;
params = propval(varargin, defaults);

if length(subj.sess) > 1
  fprintf('concatenating session events...')
end

% determine which sessions to run
if ~isempty(params.sess_filter)
  match = inStruct(subj.sess, params.sess_filter);
else
  match = true(size(subj.sess));
end
%zach changed below to avoid error in cat_structs
events = struct([]);
for sess=subj.sess(match)
  if length(subj.sess) > 1
    fprintf('%d ', sess.number)
  end
  
  % load the events struct for this session
  sess_events_file = fullfile(sess.dir, params.events_file);
  if ~exist(sess_events_file, 'file')
    warning('eeg_ana:import_events:missingEventsFile', ...
            'events file not found: %s\n', sess_events_file)
    continue
  end

  sess_events = getfield(load(sess_events_file, 'events'), 'events');

  % fill in eeg fields if they are missing
  if params.check_eeg && ( ~isfield(sess_events,'eegfile') || ...
                           ~isfield(sess_events,'artifactMS') || ...
                           all(cellfun(@isempty,{sess_events.eegfile})) )
    try
      % try to fix it one more time;
      % force alignment to run again
      prep_egi_data(subj.id, sess.dir, ...
                     'eventfiles', {sess_events_file}, ...
                     'steps_to_run', {'align'});
      
      % it must have worked! load the new events
      sess_events = getfield(load(sess_events_file, 'events'), 'events');
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
      switch get_error_id(err)
       case {'NoMatchStart', 'NoMatchEnd'}
        fprintf('Warning: alignment failed for %s.\n', ...
                sess.dir)
       case 'PulseFileNotFound'
        fprintf('Warning: pulse file not found for %s.\n', ...
                sess.dir)
       case 'NoEEGFile'
        fprintf('Warning: all events out of bounds for %s.\n', ...
                sess.dir)
       case 'CorruptedEEGFile'
        fprintf('Warning: EEG file for %s is corrupted.\n', sess.dir)
       otherwise
        % just print the error output
        warning('eeg_ana:post_process_subj:SessError', ...
                'prep_egi_data threw an error for %s:\n %s', ...
                sess.dir, getReport(err))
      end

      [sess_events(:).eegfile] = deal('');
      [sess_events(:).eegoffset] = deal(NaN);
      [sess_events(:).artifactMS] = deal(NaN);
    end
  end

  % filter the events
  if ~isempty(params.event_filter)
    sess_events = filterStruct(sess_events, params.event_filter);
  end

  % concatenate
  events = cat_structs(events, sess_events);
  
  % make sure we have a row vector
  if size(events, 1) > 1
    events = events';
  end
end
if length(subj.sess) > 1
  fprintf('\n')
end

% create an ev object
ev_dir = fullfile(res_dir, 'events');
if ~exist(ev_dir, 'dir')
  mkdir(ev_dir)
end

ev_file = fullfile(ev_dir, objfilename('events', ev_name, ...
                                       subj.id));

ev = init_ev(ev_name, 'source', subj.id, 'file', ev_file);

% save the new events
ev = set_mat(ev, events, 'hd');

fprintf('ev object "%s" created.\n', ev_name)

% add the ev object to subj
subj = setobj(subj, 'ev', ev);
