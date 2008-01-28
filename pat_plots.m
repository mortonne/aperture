function eeg = pat_plots(eeg, params, resDir, figname)
%
%PAT_PLOTS - manages event-related potential/power figures, plus
%topo plots of both voltage and power
%
% FUNCTION: eeg = pat_plots(eeg, params, resDir, figname)
%
% INPUT: eeg - struct created by init_iEEG or init_scalp
%        params - required fields: patname (specifies the name of
%                 which pattern in the eeg struct to use)
%
%                 optional fields: eventFilter (specify subset of
%                 events to use), masks (cell array containing
%                 names of masks to apply to pattern), subjects
%                 (cell array of ids of subjects to include) diff
%                 (set to 1 to plot difference of eventypes)
%                 across_subj (set to 1 to plot patterns saved in eeg.pat)
%
%        resDir - plots saved in resDir/figs
%
% OUTPUT: new eeg struct with filenames of all figures created
% saved in pat.figs
%

if ~isfield(params, 'patname')
  error('You must specify which pattern to use')
end

params = structDefaults(params, 'diff', 0,  'across_subj', 0);

if ~isfield(params, 'subjects')
  params.subjects = getStructField(eeg.subj, 'id');
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
    pat = getobj(eeg, 'pat', params.patname);
  else
    s = find(inStruct(eeg.subj, 'strcmp(id, varargin{1})', params.subjects{i}));
    id = eeg.subj(s).id;
    pat = getobj(eeg.subj(s), 'pat', params.patname);
  end
  pattern = loadPat(pat.file);
  
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
	h = plot(getStructField(pat.dim.time, 'avg'), squeeze(pattern(e,c,:)), '-k');
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
	h = plot_pow(pattern(e,c,:,:), pat.dim);
	
	fig.file{e,c} = fullfile(resDir, 'figs', [params.patname '_erpow_' id '_e' num2str(e) 'c' num2str(c) '.eps']);
	print(gcf, '-depsc', fig.file{e,c});
      end
      
    end
    
  end % channels
  
  pat = setobj(pat, 'fig', fig);
  
  load(fullfile(eeg.resDir, 'eeg.mat'));
  if strcmp(id, 'across_subj')
    eeg = setobj(eeg, 'pat', pat);
  else
    eeg.subj(s) = setobj(eeg.subj(s), 'pat', pat);
  end
  save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');
end % subjects
