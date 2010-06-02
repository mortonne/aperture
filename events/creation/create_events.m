function subj = create_events(subj, fcn_handle, fcn_input, varargin)
%CREATE_EVENTS   Create events for all sessions of a subject.
%
%  Update the events for every session in a subj structure. For each
%  session, if an events.mat file does not exist, events will be created
%  and saved. If input files are specified, and any of them have
%  recently been modified for a session, that session's events will be
%  updated.
%
%  create_events(subj, fcn_handle, fcn_input, ...)
%
%  INPUTS:
%        subj:  structure representing a number of subjects.
%
%  fcn_handle:  handle to a function that creates an events structure
%               for one session. Called as:
%                EVENTS = fcn_handle(SESS_DIR, SUBJECT, SESSION, ...)
%               where SESS_DIR is the path to the session directory,
%               SUBJECT is an identifier string, and SESSION is the
%               session number.
%
%   fcn_input:  cell array of additional inputs to fcn_handle.
%
%  OUTPUTS:
%   For each session, an events structure is saved in 
%   [sess.dir]/events.mat.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   data_dir     - relative path (from each session's directory) to pass
%                  into the events-creation function as SESS_DIR. ('')
%   output_file  - relative path (from each session's directory) to save
%                  each events structure. ('events.mat')
%   input_files  - cell array of paths to input files to check for to
%                  determine whether events should be created. For a
%                  given session, if any of the files are newer than
%                  agethresh days, or if eventsfile doesn't exist, new
%                  events will be created and saved. Paths may contain
%                  wildcards "*". ({'session.log', '*.par', '*.ann'})
%   age_thresh   - threshold for determining if a session's data have
%                  been modified recently. If any files in input_files
%                  have been modified within the past age_thresh days,
%                  events will be recreated. (.8)
%   overwrite    - if false, existing output files will not be
%                  overwritten. (true)
%   force        - if true, attempt to create and save events for each
%                  session, regardless of whether output files exist or
%                  input files have changed. (false)
%
%  EXAMPLE:
%   % update events for sessions that have been parsed in the last week
%   params = [];
%   params.agethresh = 7;
%   params.input_files = {'*.par'};
%   create_events(subj, @my_events_creation_function, {}, params);

% input checks
if ~exist('subj', 'var') || ~isstruct(subj)
  error('You must input a subj structure.')
elseif length(subj) > 1
  error('May only pass one subject. Use apply_to_subj to process all subjects.')
elseif ~exist('fcn_handle', 'var')
  error('You must pass a handle to an events-creation function.')
elseif ~isa(fcn_handle, 'function_handle')
  error('fcn must be passed as a function handle.')
end
if ~exist('fcn_input', 'var')
  fcn_input = {};
end

% set options
defaults.data_dir = '';
defaults.output_file = 'events.mat';
defaults.input_files = {'session.log', '*.par', '*.ann'};
defaults.age_thresh = .8;
defaults.overwrite = true;
defaults.force = false;
defaults.sess_filter = '';
params = propval(varargin, defaults);

pd = pwd;

% determine which sessions to run
if ~isempty(params.sess_filter)
  match = inStruct(subj.sess, params.sess_filter);
else
  match = true(size(subj.sess));
end

for sess = subj.sess(match)
  cd(sess.dir);
  
  % if force, no need to check anything
  if ~params.force
    if ~params.overwrite && exist(params.output_file, 'file');
      % file exists; move to next session
      continue
    end
    
    % get file i/o information
    if ~isempty(params.input_files)
      infiles_new = filecheck(params.input_files, params.age_thresh);
      if ~infiles_new && exist(params.output_file, 'file')
        % no modified input files, and output file already exists
        continue
      end
    end
  end

  fprintf('creating events for %s-%d using %s...\n', ...
          subj.id, sess.number, func2str(fcn_handle))

  % directory that the function will get input from
  input_dir = fullfile(sess.dir, params.data_dir);
  try
    % create events
    events = fcn_handle(input_dir, subj.id, sess.number, fcn_input{:});
  catch err
    % an error thrown by fcn_handle; move to next session
    warning('eeg_ana:create_events:eventCreationError', ...
            'Error thrown by %s processing: %s', ...
            func2str(fcn_handle), getReport(err))
  end
  
  % save the new events
  save(params.output_file, 'events');
  fprintf('saved.\n')
end

cd(pd);

function update = filecheck(files, agethresh)
  %FILECHECK   See if any files have been recently modified.
  %   UPDATE is false if none of the files in cell array
  %   FILES have been modified in the past AGETHRESH days.
  
  update = 0;
  if length(files)==0
    error('files must be a cell array containing paths')
  end
  
  for i=1:length(files)
    d = dir(files{i});
    if length(d)==0
      continue
    end
    for j=1:length(d)
      age = now - datenum(d(j).date);
      if age < agethresh
        update = 1;
        return
      end
    end
  end
%endfunction
