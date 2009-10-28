function ev_dir = get_ev_dir(ev, subdir)
%GET_EV_DIR   Get the path to an event structure's standard directory.
%
%  ev_dir = get_ev_dir(ev, subdir)
%
%  INPUTS:
%       ev:  an events object.
%
%   subdir:  string name of a subdirectory of the pattern's main
%            directory to return. If subdir does not exist, it will be
%            made. Default: ''
%
%  OUTPUTS:
%   ev_dir:  path to the requested events directory.

% input checks
if ~exist('ev', 'var') || ~isstruct(ev)
  error('You must pass an object.')
elseif ~isfield(ev,'file')
  error('ev must have a "file" field.')
end
if ~exist('subdir','var')
  subdir = '';
end

% get the requested directory
ev_dir = fullfile(fileparts(ev.file), subdir);

% make sure it exists
if ~exist(ev_dir,'dir')
  mkdir(ev_dir)
end

