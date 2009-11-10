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
elseif ~isfield(ev, 'file')
  error('ev must have a "file" field.')
end
if ~exist('subdir', 'var')
  subdir = '';
end

main_dir = fileparts(ev.file);

% fix the path if it is relative; assuming that we don't want to use
% filepaths relative to the search path
if ~ismember(filesep, main_dir)
  main_dir = fullfile('.', main_dir);
end

% make sure the main directory exists
if ~isempty(main_dir) && ~exist(main_dir, 'dir')
  mkdir(main_dir);
end

% get the requested directory
ev_dir = fullfile(main_dir, subdir);

% make sure it exists
if ~isempty(ev_dir) && ~exist(ev_dir, 'dir')
  mkdir(ev_dir)
end

