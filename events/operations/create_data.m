function ev = create_data(ev, stat_name, varargin)
%CREATE_DATA   Create a data struct from an events struct.
%
%  ev = create_data(ev, stat_name, ...)
%
%  INPUTS:
%         ev:  an events object.
%
%  stat_name:  name of the stat object to be created. Default: 'data'
%
%  OUTPUTS:
%         ev:  events object with an added stat object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   f            - handle to a function of the form:
%                   [data, ...] = fcn_handle(events, ...)
%                  (@FRdata)
%   f_input      - cell array of additional inputs to f. ({})
%   event_filter - filter string to apply to events before creating the
%                  data struct. ('')
%   overwrite    - if true, existing stat files will be overwritten.
%                  (true)
%   res_dir      - directory in which to save the data structure.
%                  (get_ev_dir(ev, 'stats'))

% input checks
if ~exist('ev', 'var') || ~isstruct(ev)
  error('You must pass an ev object.')
end
if ~exist('stat_name', 'var')
  stat_name = 'data';
end

% process options
defaults.f = @FRdata;
defaults.f_input = {};
defaults.event_filter = '';
defaults.overwrite = true;
defaults.res_dir = get_ev_dir(ev, 'stats');
params = propval(varargin, defaults);

% set the file where the data struct will be saved
stat_file = fullfile(params.res_dir, objfilename('stat', stat_name, ev.source));
if ~params.overwrite && exist(stat_file, 'file')
  fprintf('data "%s" exists. Skipping...\n', stat_name)
  return
end

fprintf('creating data struct using %s...', func2str(params.f))

% load the events
events = get_mat(ev);

if ~isempty(params.event_filter)
  events = filterStruct(events, params.event_filter);
end

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
