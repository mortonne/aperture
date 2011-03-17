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
%   source    - string indicating the source of the pattern. If empty,
%               the source will not change. ('')
%   res_dir   - directory in which to save the modified pattern and
%               events, if applicable. Default is a directory named
%               pat_name on the same level as the input pat.
%   verbose   - if true, status about renaming, overwriting, etc. will
%               be printed. (true)
%
%  NOTES:
%   It is assumed that the pattern will be saved in pat.mat (i.e., in
%   the workspace) when pat is returned. Use pat = set_mat(pat, pattern,
%   'ws'); to do this. (Otherwise, the pattern will be saved to disk
%   inside f, defeating the purpose of using this file-management
%   function). Also, any modified sub-structures of pat
%   (e.g. pat.dim.ev) should be indicated by setting the 'modified'
%   field to true.

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

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
defaults.save_as = pat.name;
defaults.source = pat.source;
defaults.res_dir = '';
defaults.split = false;
defaults.verbose = false;
params = propval(varargin, defaults);

if ~params.overwrite && strcmp(params.save_as, pat.name) ...
   && strcmp(params.source, pat.source) && params.save_mats
  % contradictory inputs; use the special default of returning to the
  % workspace
  params.save_mats = false;
end

if params.verbose
  fprintf('modifying pattern "%s"...', pat.name)
end

if strcmp(params.save_as, pat.name) && strcmp(params.source, pat.source)
  % the pattern hasn't changed name or source; we don't need to generate
  % a new file
  new_file = false;
else
  % name or source has changed, so we need a new file
  new_file = true;
end

% before modifying the pat object, make sure files, etc. are OK
if new_file
  % set new save files, regardless of whether we're saving right now
  % set the default results directory
  pat_name = params.save_as;
  pat_source = params.source;
  if isempty(params.res_dir)
    params.res_dir = fullfile(fileparts(get_pat_dir(pat)), pat_name);
  end
  
  % use "patterns" subdirectory of res_dir
  pat_dir = fullfile(params.res_dir, 'patterns');
  pat_file = fullfile(pat_dir, ...
                      objfilename('pattern', pat_name, pat_source));
else
  pat_name = pat.name;
  pat_file = pat.file;
  pat_source = pat.source;
end

% check to see if there's already a pattern there that we don't want
% to overwrite
if ~strcmp(pat_file(end-3:end), '.mat')
  full_pat_file = [pat_file '.mat'];
else
  full_pat_file = pat_file;
end
if params.save_mats && ~params.overwrite && exist(full_pat_file, 'file')
  fprintf('pattern "%s" exists. Skipping...\n', pat_name)
  return
end

% make requested modifications; pattern and events may be modified in
% the workspace
if params.split && isfield(pat.dim, 'splitdim') && ~isempty(pat.dim.splitdim)
  % get all slice patterns
  pats = [];
  split_dim = pat.dim.splitdim;
  for i = 1:patsize(pat.dim, split_dim)
    slice_pat = getfield(load(pat.file{i}, 'obj'), 'obj');
    pats = addobj(pats, slice_pat);
  end
  dim = pat.dim;
  
  % run all slices, overwriting old slices
  p = params;
  p.split = false;
  p.save_mats = true;
  p.overwrite = true;
  p.save_as = '';
  p.verbose = false;
  pats = apply_to_subj(pats, @mod_pattern, {f, f_inputs, p}, 0);
  
  % concatenate to update dimensions info
  pat_name = pat.name;
  pat_files = pat.file;
  pat = cat_patterns(pats, split_dim, 'save_mats', true, ...
                     'save_as', pat_name);
  new_dim = get_dim(pat.dim, split_dim);
  pat.dim = set_dim(dim, split_dim, dim);
  
  pat.file = pat_files;
  pat.dim.splitdim = split_dim;
  return
else
  pat = f(pat, f_inputs{:});
end

% make sure that the pattern is stored in the workspace--if not, the
% supplied f is doing something weird
if ~strcmp(get_obj_loc(pat), 'ws')
  error('pattern returned from %s should be stored in the workspace.', ...
        func2str(f))
end

% assume that the pattern is modified (the function must mark events as
% modified, if necessary)
pat.modified = true;

if new_file
  % change the name(/source) and point to the new file
  pat.name = pat_name;
  pat.file = pat_file;
  pat.source = pat_source;
  if ~exist(pat_dir, 'dir')
    mkdir(pat_dir)
  end
end

dim_info = pat.dim;
for i = 1:length(patsize(pat.dim))
  [dim_name, t, t, dim_long_name] = read_dim_input(i);

  if ~(any(ismember({'file' 'mat'}, fieldnames(dim_info.(dim_name)))) ...
     && dim_info.(dim_name).modified)
    continue
  end
    
  % this is a new-format object that has been modified
  dim = get_dim(dim_info, dim_name);
  
  % make sure the type field is set
  dim_info.(dim_name).type = dim_name;
  
  % set the file name
  dim_dir = get_pat_dir(pat, dim_long_name);
  dim_file = fullfile(dim_dir, ...
                      objfilename(dim_long_name, pat.name, pat.source));
  dim_info.(dim_name).file = dim_file;

  % save
  if params.save_mats
    if ~params.overwrite && exist(dim_file, 'file')
      dim_info.(dim_name).file = strrep(dim_file, '.mat', '_mod.mat');
    end
    dim_info = set_dim(dim_info, dim_name, dim, 'hd');
  end
end
pat.dim = dim_info;

if params.save_mats && strcmp(get_obj_loc(pat), 'ws')
  % save the pattern
  pat = move_obj_to_hd(pat);
  if params.verbose
    if new_file
      fprintf('saved as "%s".\n', pat.name)
    else
      fprintf('saved.\n')
    end
  end
elseif params.verbose
  % nothing to do
  if new_file
    fprintf('returning as "%s".\n', pat.name)
  else
    fprintf('updated.\n')
  end
end
