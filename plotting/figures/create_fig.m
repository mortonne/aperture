function obj = create_fig(obj,fig_name,fcn_handle,fcn_inputs)
%CREATE_FIG   Create figures from information in an object.
%
%  obj = create_fig(obj, fig_name, fcn_handle, fcn_inputs)
%
%  This function provides a way to make plots from an object and keep
%  track of the figure files in a "fig" object. fig objects can then
%  be passed into report-creation functions to make PDFs of many figures.
%
%  INPUTS:
%         obj:  a structure that contains information that can be used
%               to make a plot.
%
%    fig_name:  string identifier for the new fig object; this will
%               become fig.name. Default is "figure".
%
%  fcn_handle:  a function that takes obj as its first input, fig_name
%               as its second input, and returns a cell array of paths 
%               to printed figures (e.g. {figure1.eps, figure2.eps, ...}).
%                
%  fcn_inputs:  additional inputs to fcn_handle after obj and fig_name.
%
%  OUTPUTS:
%         obj:  same as the input obj, but with a fig object added.
%               fig is a structure with fields:
%                'name'    string identifier
%                'file'    cell array of paths to saved figures
%                'source'  same as obj.name
%
%  EXAMPLE:
%   % create a new pattern named volt
%   subj = create_pattern(subj, @sessVoltage, struct, 'volt');
%
%   % get the pat object
%   pat = getobj(subj,'pat','volt');
%
%   % plot all events
%   pat = create_fig(pat, 'erp', @pat_erp, {});

if ~exist('fig_name','var')
  fig_name = 'figure';
end
if ~exist('fcn_inputs','var')
  fcn_inputs = {};
  elseif ~iscell(fcn_inputs)
  error('fcn_inputs must be a cell array.')
  elseif ~exist('fcn_handle','var')
  error('You must specify a figure-creation script.')
  elseif ~isa(fcn_handle,'function_handle')
  error('fcn_handle must be a function handle.')
  elseif ~exist('obj','var')
  error('You must pass a source object for creating the figures.')
  elseif ~isstruct(obj)
  error('obj must be a structure.')
end

% run the figure creation script, which should return a cell array
% of paths to saved figures
files = fcn_handle(obj, fig_name, fcn_inputs{:});

% create a new fig object
fig = init_fig(fig_name, files, obj.name);

% add fig to obj
obj = setobj(obj, 'fig', fig);
