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
%  If input pat is saved to disk, the new pattern will be saved in a
%  new file in [res_dir]/patterns.  If events are modified, and they are
%  saved on disk, the modified events will be saved in
%  [res_dir]/events.  In case the events are used by other objects, they
%  will be saved to a new file even if pat_name doesn't change.
%
%  pat = mod_pattern(pat, f, f_inputs, ...)
%
%  INPUTS:
%       pat:  a pattern object.
%
%         f:  handle to a function of the form:
%              pat = f(pat, ...)
%
%  f_inputs:  cell array of additional inputs to f.
%
%  OUTPUTS:
%       pat:  a modified pattern object, named pat_name.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   save_as   - string identifier to name the modified pattern. If
%               empty, the name will not change. ('')
%   overwrite - if true, existing patterns will be overwritten. (false
%               if pattern is stored on disk, true if pattern is stored
%               in workspace or if save_mats is false)
%   save_mats - if true, and input mats are saved on disk, modified mats
%               will be saved to disk. If false, the modified mats will
%               be stored in the workspace, and can subsequently be
%               moved to disk using move_obj_to_hd. This option is
%               useful if you want to make a quick change without
%               modifying a saved pattern. (true)
%   res_dir   - directory in which to save the modified pattern and
%               events, if applicable. Default is a directory named
%               pat_name on the same level as the input pat.

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
defaults.save_as = '';
defaults.save_mats = true;
defaults.res_dir = '';
params = propval(varargin, defaults, 'strict', false);

% get the location of the input pat; this will set the default of
% whether the new pattern is saved to workspace or hard drive
pat_loc = get_obj_loc(pat);
ev_loc = get_obj_loc(pat.dim.ev);

if strcmp(pat_loc, 'ws') || ~params.save_mats
  defaults.overwrite = true;
else
  defaults.overwrite = false;
end
params = propval(params, defaults);

fprintf('modifying pattern "%s"...', pat.name)

if strcmp(params.save_as, pat.name)
  params.save_as = '';
end

% before modifying the pat object, make sure files, etc. are OK
if ~isempty(params.save_as)
  % set the default results directory
  if isempty(params.res_dir)
    params.res_dir = fullfile(fileparts(get_pat_dir(pat)), params.save_as);
  end
  
  % use "patterns" subdirectory of res_dir
  pat_dir = fullfile(params.res_dir, 'patterns');
  pat_file = fullfile(pat_dir, ...
                      objfilename('pattern', params.save_as, pat.source));
  
  % check to see if there's already a pattern there that we don't want
  % to overwrite
  if strcmp(pat_loc, 'hd') && ~params.overwrite && exist(pat_file, 'file')
    fprintf('pattern "%s" exists in new file. Skipping...\n', params.save_as)
    return
  end
  
  % make sure the parent directory exists
  if ~exist(pat_dir, 'dir')
    mkdir(pat_dir);
  end
else
  % should we overwrite this pattern?  Regardless of hd or ws
  if ~params.overwrite && exist_mat(pat)
    fprintf('pattern "%s" exists. Skipping...\n', pat.name)
    return
  end
end

% for ease of passing things around, temporarily move the mats to the
% workspace, if they aren't already
pat = move_obj_to_workspace(pat);
pat.dim.ev = move_obj_to_workspace(pat.dim.ev);

% make requested modifications; pattern and events may be modified in
% the workspace
pat = f(pat, f_inputs{:});

if ~isempty(params.save_as)
  % change the name and point to the new file
  pat.name = params.save_as;
  pat.file = pat_file;
end

% if event have been modified, change the filepath. We don't want to
% overwrite any source events that might be used for other patterns, 
% etc., so we'll change the path even if we are using the same 
% pat_name as before. Even if we're not saving, we'll change the file
% in case events are saved to disk later.
if pat.dim.ev.modified
  events_dir = get_pat_dir(pat, 'events');
  pat.dim.ev.file = fullfile(events_dir, objfilename('events', ...
                                                    pat.name, pat.source));
end

% either move unmodified events back to disk, or save modified events
% to their new file
if params.save_mats && strcmp(ev_loc, 'hd')
  pat.dim.ev = move_obj_to_hd(pat.dim.ev);
end

% save the pattern where we found it
if params.save_mats && strcmp(pat_loc, 'hd')
  pat = move_obj_to_hd(pat);
  if ~isempty(params.save_as)
    fprintf('saved as "%s".\n', pat.name)
  else
    fprintf('saved.\n')
  end
else
  % already should be in pat.mat
  if ~isempty(params.save_as)
    fprintf('returning as "%s".\n', pat.name)
  else
    fprintf('updated.\n')
  end
end
