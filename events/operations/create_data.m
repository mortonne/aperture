function ev = create_data(ev,fcn_handle,fcn_input,res_dir)
%CREATE_DATA   Create a data struct from an events struct.
%
%  ev = create_data(ev,fcn_handle,fcn_input,res_dir)
%
%  INPUTS:
%          ev:  an events object.
%
%  fcn_handle:  handle to a function of the form:
%                data = fcn_handle(events, ...)
%
%   fcn_input:  cell array of additional inputs to fcn_handle.
%
%     res_dir:  path to the directory where the data structure
%               will be saved. Default: fileparts(ev.file)
%
%  OUTPUTS:
%          ev:  events object with a datafile field added, which
%               gives the path to the data structure.

% input checks
if ~exist('ev','var')
  error('You must pass an ev object.')
  elseif ~exist('fcn_handle','var')
  error('You must pass a handle to a data structure creation function.')
end
if ~exist('fcn_input','var')
  fcn_input = {};
end
if ~exist('res_dir','var')
  res_dir = fileparts(fileparts(ev.file));
end

% prepare the directory
data_dir = fullfile(res_dir, 'data');
if ~exist(data_dir, 'dir')
  mkdir(data_dir);
end

% load the events
events = load_events(ev);

% create the data struct
fprintf('creating data struct using %s...', func2str(fcn_handle))

ev.datafile = fullfile(res_dir, 'data', sprintf('data_%s.mat', ev.source));

try
  data = fcn_handle(events, fcn_input{:});
  catch
  err = lasterror;
  fprintf('Warning: Error thrown by %s:\n', func2str(fcn_handle))
  fprintf('%s\n', err.message)
  return
end

save(ev.datafile,'data')
fprintf('saved.\n')
