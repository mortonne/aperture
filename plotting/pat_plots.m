function exp = pat_plots(exp, params, figname, resDir)
%
%PAT_PLOTS - manages event-related potential/power figures, plus
%topo plots of both voltage and power
%
% FUNCTION: exp = pat_plots(exp, params, figname, resDir)
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

if ~isfield(params, 'patname')
  error('You must specify which pattern to use')
end
if ~exist('resDir', 'var')
  resDir = fullfile(exp.resDir, params.patname);
end
if ~exist('figname', 'var')
  figname = 'plots';
end

params = structDefaults(params, 'diff', 0,  'across_subj', 0,  'sym', {'-r', '-b'});

if ~isfield(params, 'subjects')
  params.subjects = getStructField(exp.subj, 'id');
end
if params.across_subj
  params.subjects = [params.subjects 'across_subj'];
end

if ~exist(fullfile(resDir, 'figs'), 'dir')
  mkdir(fullfile(resDir, 'figs'))
end

clf reset

for i=1:length(params.subjects)
  
  % get the pat object, load pattern
  if strcmp(params.subjects{i}, 'across_subj')
    id = 'across_subj';
    pat = getobj(exp, 'pat', params.patname);
  else
    s = find(inStruct(exp.subj, 'strcmp(id, varargin{1})', params.subjects{i}));
    id = exp.subj(s).id;
    pat = getobj(exp.subj(s), 'pat', params.patname);
  end
  pattern = loadPat(pat, params, 0);
  
  fig.name = figname;
  fig.type = 'erp';
  fig.file = {};
  fig.params = params;
  
  if params.diff & size(pattern,1)==2
    pattern = pattern(2,:,:,:)-pattern(1,:,:,:);
  end
  
  for c=1:size(pattern,2)
    
    if isempty(pat.dim.freq) % plotting voltage values
      for e=1:size(pattern,1)
	h = plot(getStructField(pat.dim.time, 'avg'), squeeze(pattern(e,c,:)), params.sym{mod(e,length(params.sym))+1});
	xlabel('Time (ms)')
	ylabel('Voltage')
	hold on
      end
      hold off
      
      if sum(~isnan(get(h, 'YData')))>0
	fig.file{1,c} = fullfile(resDir, 'figs', [params.patname '_erp_' id 'e1c' num2str(c) '.eps']);
	print(gcf, '-depsc', fig.file{1,c});
      end
      
    else % plotting power values
      for e=1:size(pattern,1)
	h = plot_pow(squeeze(pattern(e,c,:,:))', pat.dim);
	
	fig.file{e,c} = fullfile(resDir, 'figs', [params.patname '_erpow_' id '_e' num2str(e) 'c' num2str(c) '.eps']);
	print(gcf, '-depsc', fig.file{e,c});
      end
      
    end
    
  end % channels
  
  pat = setobj(pat, 'fig', fig);

  % update exp with filenames of the new figures
  if strcmp(id, 'across_subj')
    exp = update_exp(exp, 'pat', pat);
  else
    exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat);
  end
  
end % subjects
