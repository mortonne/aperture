function [ev,err] = ev_plots(ev, params, figname, resdir)
%EV_PLOTS   Make figures from an events struct or data struct.
%   EV = EV_PLOTS(EV,PARAMS,FIGNAME,resdir) creates figures
%   using data stored in ev and options in the PARAMS struct.
%   A modified ev with fig object named FIGNAME is returned;
%   ev.fig includes a cell array of the filenames of all figures.
%
%   Params:
%     'useEvents'     If true (default is false), events will be
%                     used instead of the corresponding data struct
%     'plotfcn'       Handle to a function that takes either events
%                     or data as input, and creates plots. If
%                     the function creates multiple plots, the
%                     function must return a vector of figure handles
%                     as its first argument.
%     'plotfcninput'  Cell array of inputs to the plot function that
%                     will be input after data or events
%     'title'         String containing the title of the figure
%

if ~exist('resdir','var')
  [dir,filename] = fileparts(ev.file);
  resdir = fullfile(fileparts(fileparts(dir)), ev.name);
end
if ~exist('figname', 'var')
  figname = 'plots';
end
if ~exist('params','var')
  params = struct;
end

params = structDefaults(params, 'useEvents',0, 'plotfcn',@spc, 'plotfcninput',{1}, 'title','', 'increment_fig',1);

if ~exist(fullfile(resdir, 'figs'), 'dir')
  mkdir(fullfile(resdir, 'figs'));
end

clf reset

% check input files
err = prepFiles(ev.file, {}, params);
if err
  return
end

% load the input to the plotting function
if params.useEvents
  load(ev.file);
  input = events;
  else
  load(ev.datafile);
  input = data;
end

% run the plotting function
h_vec = params.plotfcn(input,params.plotfcninput{:});
if ~ishandle(h_vec(1))
  h_vec = gcf;
end

% save out .fig files
for i=1:length(h_vec)
  h = h_vec(i);
  
  if length(h_vec)==1
    filename = figname;
    else
    filename = sprintf('%s_%d', figname, i);
  end
  files{i} = fullfile(resdir,'figs',filename);
  hgsave(h,files{i});
end

% store info in the fig object
fig = init_fig(figname,'behavioral',files,params,params.title);

% add the fig object to ev
ev = setobj(ev, 'fig', fig);

if params.increment_fig
  drawnow
  figure(gcf+1)
end
