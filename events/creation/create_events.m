function subj = create_events(subj,fcn_handle,fcn_input,varargin)
%CREATE_EVENTS   Create events for each session in a subj structure.
%
%  create_events(subj, fcn_handle, fcn_input, varargin)
%
%  Update the events for every session in a subj structure. For each session,
%  if an events.mat file does not exist, events will be created and saved.
%  Also, events structures will be updated if any of the files in files2check
%  have been modified recently (default: 0.8 days). The default files2check 
%  include session.log and any .par files.
%
%  INPUTS:
%        subj:  structure representing a number of subjects.
%
%  fcn_handle:  handle to a function that creates an events structure
%               for one session. Must take session directory as first input,
%               followed by subject ID and session number.
%
%   fcn_input:  cell array of additional inputs to fcn_handle.
%
%    varargin:  additional arguments can be parameter-value pairs that change
%               options. See below for options.
%
%  OUTPUTS:
%   For each session, an events structure is saved in [sess.dir]/events.mat.
%
%  OPTIONS:
%   logfiledir:  relative path (from each session's directory) to pass into
%                the events-creation function. Default: ''
%
%   eventsfile:  relative path (from each session's directory) to save each
%                events structure. Default: 'events.mat'
%
%  files2check:  cell array of paths to input files to check for to determine
%                whether events should be created. For a given session, if any 
%                of the files are newer than agethresh days, or if eventsfile
%                doesn't exist, new events will be created and saved. Paths may
%                contain wildcards "*".
%
%    agethresh:  threshold, in days, for determining if a session's data have
%                been modified and an events structure therefore needs to be
%                recreated.
%
%  EXAMPLE:
%   % update events for any session that has been parsed in the last week
%   options = {'agethresh', 7, 'files2check', {'*.par'}};
%   create_events(subj, @my_events_creation_function, {}, options{:});

% input checks
if ~exist('subj','var')
  error('You must input a subj structure.')
  elseif ~exist('fcn_handle','var')
  error('You must pass a handle to an events-creation function.')
end
if ~exist('fcn_input','var')
  fcn_input = {};
end

% parse options
def.logfiledir = '';
def.eventsfile = 'events.mat';
def.files2check = {'session.log', '*.par'};
def.agethresh = .8;
[eid,emsg,logfiledir,eventsfile,files2check,agethresh] = getargs(fieldnames(def),struct2cell(def),varargin{:});

sess_to_remove = [];
for this_subj=subj
  for i=1:length(this_subj.sess)
    sess = this_subj.sess(i);
    cd(sess.dir);
    
    % check for recently modified files
    if exist(eventsfile,'file') && ~isempty(files2check) && ~filecheck(files2check,agethresh)
      % none found for this session, and an events structure exists; skip
      continue
    end
    
    % create events and save
    fprintf('Creating events for %s, session %d using %s...', ...
            this_subj.id, sess.number, func2str(fcn_handle))
    try
      events = fcn_handle(fullfile(sess.dir,logfiledir), this_subj.id, sess.number, fcn_input{:});
      save(eventsfile, 'events');
      fprintf('saved.\n')
    catch err
      warning('eeg_ana:create_events:eventCreationError', ...
              'Error thrown by %s processing: %s', func2str(fcn_handle), getReport(err))
    end
  end
end


function update = filecheck(files,agethresh)
  %FILECHECK   See if any files have been recently modified.
  %   UPDATE is false if none of the files in cell array
  %   FILES have been modified in the past AGETHRESH days.
  %
  
  update = 0;
  if length(files)==0
    error('files must be a cell array containing paths')
  end
  
  for i=1:length(files)
    d = dir(files{i});
    if length(d)==0
      return
    end
    for i=1:length(d)
      age = now - datenum(d(i).date);
      if age<agethresh
        update = 1;
        return
      end
    end
  end
%endfunction
