function varargout = run_fieldtrip(f, varargin)

p = path;
fieldtrip_dir = fileparts(which('timelockanalysis'));
addpath(genpath(fieldtrip_dir));
varargout = cell(1, nargout(f));
[varargout{:}] = f(varargin{:});
path(p);

