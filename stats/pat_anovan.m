function exp = pat_anovan(exp, params, statname, resDir)
%exp = pat_anovan(exp, params, statname, resDir)

if ~exist('resDir', 'var')
  resDir = fullfile(exp.resDir, 'eeg', params.patname);
end
if ~exist('statname', 'var')
  statname = 'anovan';
end
if isstr(params.fields)
  params.fields = {params.fields};
end

params = structDefaults(params, 'masks', {},  'eventFilter', '',  'chanFilter', '',  'lock', 1,  'overwrite', 0);

for s=1:length(exp.subj)
  pat = getobj(exp.subj(s), 'pat', params.patname);

  % set where the stats will be saved
  statfile = fullfile(resDir, 'stats', [params.patname '_anovan_' exp.subj(s).id '.mat']);
  
  % check input files and prepare output files
  if prepFiles(pat.file, statfile, params)~=0
    continue
  end

  fprintf('\nStarting ANOVAN for %s...\n', exp.subj(s).id);
  
  % initialize the stat object
  stat = init_stat(statname, statfile, params);
  
  % load pattern and events
  [pattern, events] = loadPat(pat, params, 1);
  
  % make the regressors
  group = cell(1, length(params.fields));
  for i=1:length(params.fields)
    group{i} = [group{i}; getStructField(events, params.fields{i})'];
    stat.factor(i).name = params.fields{i};
    stat.factor(i).vals = unique(group{i});
  end
  
  p = NaN(length(params.fields)+1, size(pattern,2), size(pattern,3), size(pattern,4));
  % do the anova
  fprintf('Channel: ');
  for c=1:size(pattern,2)
    fprintf('%s ', pat.dim.chan(c).label);
    for t=1:size(pattern,3)
      for f=1:size(pattern,4)
	p(:,c,t,f) = anovan(squeeze(pattern(:,c,t,f)), group, 'display', 'off', params.anovan_in{:});
      end
    end
  end
  fprintf('\n');
  
  save(stat.file, 'p');
  
  % update the exp struct
  exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat.name, 'stat', stat);
end