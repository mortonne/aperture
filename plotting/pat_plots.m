function [pat,err] = pat_plots(pat, params, figname, resDir)
%PAT_PLOTS   Make figures from a pattern.
%   PAT = PAT_PLOTS(PAT,PARAMS,FIGNAME,RESDIR) creates figures
%   using data stored in PAT and options in the PARAMS struct.
%   A modified PAT with fig object named FIGNAME is returned;
%   PAT.fig includes a cell array of the filenames of all figures.
%
%   Params:
%     'diff'        If true (default is false), and the events
%                   dimension of the pattern has length 2, the
%                   difference will be taken before plotting
%     'plotsig'     If true (default), significance will be
%                   loaded from pat.stat.file (which must contain
%                   a variable named 'p') and used in the plot
%     'whichStat'   Specifies which p-values to use. whichStat{1}
%                   gives the name of the stat object to use,
%                   and whichStat{2} (optional) indicates which
%                   event of 'p' to use
%     'powrange'    If the pattern has a frequency dimension,
%                   indicates the c-range for the colorbar
%     'p_range'     If plotting significance, indicates what
%                   p-values to plot as significant and more
%                   significant. Ex: [0.005, 0.05]
%     'printinput'  Specifies how each figure is printed. See
%                   PRINT for options (default '-depsc')
%

if ~exist('resDir','var')
  [dir,filename] = fileparts(pat.file);
  resDir = fullfile(fileparts(fileparts(dir)), pat.name);
end
if ~exist('figname', 'var')
  figname = 'plots';
end
if ~exist('params','var')
  params = struct;
end

% relative filenames make compiling reports much easier!
cd(resDir)

params = structDefaults(params, 'diff', 0,  'plotsig', 1,  'whichStat', {[], []},  'powrange', [-.3 .3],  'p_range', [0.05 0.005], 'printinput', '-depsc');

if ~exist(fullfile(resDir, 'figs'), 'dir')
  mkdir(fullfile(resDir, 'figs'));
end

clf reset

if ~params.plotsig
  % check input files
  err = prepFiles(pat.file, {}, params);
  if err
    return
  end
  else
  err = 0;
end

% get dimension info
timeMS = [pat.dim.time.avg];

% power or voltage?
if length(pat.dim.freq)>1
  power = 1;
  else
  power = 0;
end

if params.diff | ~params.plotsig | ~power
  % we need the pattern
  pattern = loadPat(pat, params);
end

if params.diff
  % get the difference between two event types
  if size(pattern,1)~=2
    error('Can only take difference if there are two event types');
  end
  pattern = pattern(2,:,:,:)-pattern(1,:,:,:);
end

if params.plotsig
  % we need to load p-vals from the stat struct
  stat = getobj(pat, 'stat', params.whichStat{1});
  load(stat.file);

  if ~exist('p', 'var')
    error('Stat file must contain a variable named "p"');
  end

  % if the statistic has multiple p-vals, choose which one to plot
  if ~isempty(params.whichStat{2})
    p = p(params.whichStat{2},:,:,:);
  end

  if power
    % we can only show one pattern at a time, so combine p and pattern
    if params.diff
      p = p.*sgn(pattern);
    end
    pattern = p;
  end
end

if ~power
  % ERP PLOTS
  fig = init_fig(figname, 'erp', {}, params);

  for c=1:size(pattern,2)
    if params.plotsig
      h = plot_erp(timeMS, squeeze(pattern(1,c,:))', squeeze(pattern(2,c,:))', squeeze(p(1,c,:))');
    else
      h = plot_erp(timeMS, squeeze(pattern(1,c,:))', squeeze(pattern(2,c,:)));
    end

    %if sum(~isnan(get(h, 'YData')))>0
      fig.file{1,c} = fullfile('figs', sprintf('%s_erp_%s_%s', pat.name, pat.source,pat.dim.chan(c).label));
      print(gcf, params.printinput, fig.file{1,c});
    %end
  end

elseif power
  % SPECTROGRAMS
  fig = init_fig(figname, 'power', {}, params);

  for e=1:size(pattern,1)
    for c=1:size(pattern,2)
      if params.plotsig
        h = plot_pow_sig(shiftdim(pattern(e,c,:,:),2)', pat.dim, params.p_range);
      else
        h = plot_pow(shiftdim(pattern(e,c,:,:),2)', pat.dim, params.powrange);
      end
      filename = sprintf('%s_%s_%s_e%dc%d', pat.name, figname, pat.source, e, c);
      fig.file{e,c} = fullfile('figs', filename);

      print(gcf, params.printinput, fig.file{e,c});
    end
  end
end

% add the fig object to pat
pat = setobj(pat, 'fig', fig);
