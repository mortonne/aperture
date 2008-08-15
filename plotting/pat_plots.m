function [pat,status] = pat_plots(pat, params, figname, title, resDir)
%
%PAT_PLOTS - manages event-related potential/power figures, plus
%topo plots of both voltage and power
%
% FUNCTION: exp = pat_plots(exp, params, figname, title, resDir)
%
% INPUT: exp - struct created by init_iEEG or init_scalp
%        params - required fields: patname (specifies the name of
%                 which pattern in the exp struct to use)
%
%                 optional fields: eventFilter (specify subset of
%                 events to use), masks (cell array containing
%                 names of masks to apply to pattern), subjects
%                 (cell array of ids of subjects to include) diff
%                 (set to 1 to plot difference of eventypes)
%                 across_subj (set to 1 to plot patterns saved in exp.pat)
%
%        resDir - plots saved in resDir/figs
%
% OUTPUT: new exp struct with filenames of all figures created
% saved in pat.figs
%

if ~exist('resDir','var')
  [dir,filename] = fileparts(pat.file);
  resDir = fullfile(fileparts(fileparts(dir)), pat.name);
end
if ~exist('figname', 'var')
  figname = 'plots';
end
if ~exist('title', 'var')
  title = 'plots';
end
if ~exist('params','var')
  params = struct;
end

status = 1;

% relative filenames make compiling reports much easier!
cd(resDir)

params = structDefaults(params, 'diff', 0,  'plotsig', 1,  'whichStat', {[], []},  'powrange', [-.3 .3],  'p_range', [0.05 0.005], 'lock', 0, 'overwrite', 1);

if ~exist(fullfile(resDir, 'figs'), 'dir')
  mkdir(fullfile(resDir, 'figs'));
end

clf reset

% check input files
if prepFiles(pat.file, {}, params)~=0
  pat = [];
  return
end

% get dimension info
timeMS = [pat.dim.time.avg];

% power or voltage?
if length(pat.dim.freq)>1
  power = 1;
end

if params.diff | ~params.plotsig
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

    if 1%sum(~isnan(get(h, 'YData')))>0
      fig.file{1,c} = fullfile('figs', sprintf('%s_erp_%s_e%dc%d', params.patname, id,e,c));
      print(gcf, '-depsc', fig.file{1,c});
    end
  end

elseif power
  % SPECTROGRAMS
  fig = init_fig(figname, 'power', {}, params);

  for e=1:size(pattern,1)
    for c=1:size(pattern,2)
      if params.plotsig

        h = plot_pow_sig(shiftdim(pattern(e,c,:,:),2)', pat.dim, params.p_range);
        filename = sprintf('%s_erpow_sig_%s_e%dc%d.eps', pat.name, pat.source, e, c);
      else
        h = plot_pow(shiftdim(pattern(e,c,:,:),2)', pat.dim, params.powrange);
        filename = sprintf('%s_erpow_%s_e%dc%d.eps', pat.name, pat.source, e, c);

      end
      fig.file{e,c} = fullfile('figs', filename);

      print(gcf, '-depsc', fig.file{e,c});
    end
  end
end

% add the fig object to pat
pat = setobj(pat, 'fig', fig);
