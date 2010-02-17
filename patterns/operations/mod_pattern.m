function pat = mod_pattern(pat, f, f_inputs, varargin)
%MOD_PATTERN   Modify an existing pattern.
%
%  Use this function to modify existing patterns. You can either save
%  the new pattern under a different name, or overwrite the old one.  To
%  save under a new name, set save_as to the new name.  The output pat
%  object will have that name.
%
%  By default, modified patterns will be saved in a subdirectory of the
%  parent of the main directory of the input pattern.  The new pattern's
%  main directory will be named pat_name.
%
%  If input pat is saved to disk, the new pattern will be saved in a new
%  file in [res_dir]/patterns.  If events are modified, and they are
%  saved on disk, the modified events will be saved in [res_dir]/events.
%  In case the events are used by other objects, they will be saved to a
%  new file even if pat_name doesn't change.
%
%  This function is designed to handle modifications to the pattern
%  itself (and corresponding changes to the metadata in pat). If you
%  just want to modify the pat object, without changing the pattern,
%  using this function is probably not the way to go.
%
%  pat = mod_pattern(pat, f, f_inputs, ...)
%
%  INPUTS:
%       pat:  a pattern object.
%
%         f:  handle to a function of the form:
%              pat = f(pat, ...)
%             See notes below for more information.
%
%  f_inputs:  cell array of additional inputs to f.
%
%  OUTPUTS:
%       pat:  a modified pattern object, named pat_name.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   save_mats - if true, and input mats are saved on disk, modified mats
%               will be saved to disk. If false, the modified mats will
%               be stored in the workspace, and can subsequently be
%               moved to disk using move_obj_to_hd. This option is
%               useful if you want to make a quick change without
%               modifying a saved pattern. (true)
%   overwrite - if true, existing patterns on disk will be overwritten.
%               (false)
%   save_as   - string identifier to name the modified pattern. If
%               empty, the name will not change. ('')
%   res_dir   - directory in which to save the modified pattern and
%               events, if applicable. Default is a directory named
%               pat_name on the same level as the input pat.
%
%  NOTES:
%   It is assumed that the pattern will be saved in pat.mat (i.e., in
%   the workspace) when pat is returned. Use pat = set_mat(pat, pattern,
%   'ws'); to do this. (Otherwise, the pattern will be saved to disk
%   inside f, defeating the purpose of using this file-management
%   function). Also, any modified sub-structures of pat
%   (e.g. pat.dim.ev) should be indicated by setting the 'modified'
%   field to true.

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must pass a pattern object.')
elseif isempty(pat)
  error('The input pat object is empty.')
end
if ~isfield(pat, 'modified')
  pat.modified = false;
end
if ~exist('f', 'var') || ~isa(f, 'function_handle')
  error('You must pass a function handle.')
end
if ~exist('f_inputs', 'var')
  f_inputs = {};
end

% set default params
defaults.save_mats = true;
defaults.overwrite = false;
defaults.save_as = '';
defaults.res_dir = '';
params = propval(varargin, defaults);

fprintf('modifying pattern "%s"...', pat.name)

if strcmp(params.save_as, pat.name)
  params.save_as = '';
end

% before modifying the pat object, make sure files, etc. are OK
if ~isempty(params.save_as)
  % set new save files, regardless of whether we're saving right now
  % set the default results directory
  pat_name = params.save_as;
  if isempty(params.res_dir)
    params.res_dir = fullfile(fileparts(get_pat_dir(pat)), pat_name);
  end
  
  % use "patterns" subdirectory of res_dir
  pat_dir = fullfile(params.res_dir, 'patterns');
  pat_file = fullfile(pat_dir, ...
                      objfilename('pattern', pat_name, pat.source));
else
  pat_name = pat.name;
  pat_file = pat.file;
end

% check to see if there's already a pattern there that we don't want
% to overwrite
if params.save_mats && ~params.overwrite && exist(pat_file, 'file')
  fprintf('pattern "%s" exists. Skipping...\n', pat_name)
  return
end

% make requested modifications; pattern and events may be modified in
% the workspace
pat = f(pat, f_inputs{:});

% make sure that the pattern is stored in the workspace--if not, the
% supplied f is doing something weird
if ~strcmp(get_obj_loc(pat), 'ws')
  error('pattern returned from %s should be stored in the workspace.', ...
        func2str(f))
end

% assume that the pattern is modified (the function must mark events as
% modified, if necessary)
pat.modified = true;

if ~isempty(params.save_as)
  % change the name and point to the new file
  pat.name = pat_name;
  pat.file = pat_file;
  if ~exist(pat_dir, 'dir')
    mkdir(pat_dir)
  end
end

if pat.dim.ev.modified
  % if event have been modified, change the filepath. We don't want to
  % overwrite any source events that might be used for other patterns, 
  % etc., so we'll change the path even if we are using the same 
  % pat_name as before. Even if we're not saving, we'll change the file
  % in case events are saved to disk later.
  events_dir = get_pat_dir(pat, 'events');
  ev_file = fullfile(events_dir, objfilename('events', pat.name, pat.source));
  pat.dim.ev.file = ev_file;
  
  if params.save_mats
    if ~params.overwrite && exist(ev_file, 'file')
      pat.dim.ev.file = strrep(ev_file, '.mat', '_mod.mat');
    end
    
    % save events to disk
    pat.dim.ev = move_obj_to_hd(pat.dim.ev);
  end
end

if params.save_mats && strcmp(get_obj_loc(pat), 'ws')
  % save the pattern
  pat = move_obj_to_hd(pat);
  if ~isempty(params.save_as)
    fprintf('saved as "%s".\n', pat.name)
  else
    fprintf('saved.\n')
  end
else
  % nothing to do
  if ~isempty(params.save_as)
    fprintf('returning as "%s".\n', pat.name)
  else
    fprintf('updated.\n')
  end
end
