function ev = create_data(ev, stat_name, params, res_dir)
%CREATE_DATA   Create a data struct from an events struct.
%
%  ev = create_data(ev, stat_name, params, res_dir)
%
%  INPUTS:
%         ev:  an events object.
%
%  stat_name:  name of the stat object to be created.
%
%     params:  structure with options for creating the data structure.
%              See below.
%
%    res_dir:  path to the directory where the data structure will be
%              saved.  Default is the "stat" subdirectory of the events.
%
%  OUTPUTS:
%         ev:  events object with an added stat object.
%
%  PARAMS:
%  All fields are optional. Defaults are shown in parentheses.
%   f         - handle to a function of the form:
%                data = fcn_handle(events, ...)
%               (@FRdata)
%   f_input   - cell array of additional inputs to f. ({})
%   overwrite - if true, existing stat files will be overwritten. (true)

% input checks
if ~exist('ev', 'var')
  error('You must pass an ev object.')
end
if ~exist('stat_name', 'var')
  stat_name = 'data';
end
if ~exist('params', 'var')
  params = struct;
end
if ~exist('res_dir','var')
  res_dir = get_ev_dir(ev, 'stats');
end

% process options
defaults.f = @FRdata;
defaults.f_input = {};
defaults.overwrite = true;
params = propval(params, defaults);

% set the file where the data struct will be saved
stat_file = fullfile(res_dir, objfilename('stat', stat_name, ev.source));
if ~params.overwrite && exist(stat_file, 'file')
  fprintf('data "%s" exists. Skipping...\n', stat_name)
  return
end

fprintf('creating data struct using %s...', func2str(params.f))

% load the events
events = get_mat(ev);

% attempt to create the data struct
try
  data = params.f(events, params.f_input{:});
catch
  err = lasterror;
  fprintf('Warning: Error thrown by %s:\n', func2str(params.f))
  fprintf('%s\n', err.message)
  return
end

% make a stat object to hold the data structure
stat = init_stat(stat_name, stat_file, ev.source, params);

% save
save(stat.file, 'data')
ev = setobj(ev, 'stat', stat);
fprintf('saved.\n')
