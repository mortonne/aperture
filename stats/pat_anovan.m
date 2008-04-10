function exp = pat_anovan(exp, params, statname, resDir)

if ~exist('resDir', 'var')
  resDir = fullfile(exp.resDir, 'eeg', params.patname);
end
if ~exist('statname', 'var')
  statname = 'anovan';
end

for s=1:length(exp.subj)
  pat = getobj(exp.subj, 'pat', params.patname);

  % set where the stats will be saved
  statfile = fullfile(resDir, 'stats', [params.patname '_anovan_' exp.subj(s).id '.mat']);
  
  % check input files and prepare output files
  if prepFiles(pat.file, statfile, params)~=0
    continue
  end

  % initialize the stat object
  stat.name = statname;
  stat.file = statfile;
  
  % load pattern and events
  [pattern, events] = loadPat(pat.file, params, 1);
  
  % make the regressors
  group = cell(1, length(params.fields));
  for i=1:length(params.fields)
    group{i} = [group{i}; getStructField(events, params.fields{i})'];
  end
  
  % do the anova
  for c=1:size(pattern,2)
    for t=1:size(pattern,3)
      for f=1:size(pattern,4)
	p(:,c,t,f) = anovan(squeeze(pattern(:,c,t,f)), group);
      end
    end
  end
  
  save(stat.file, 'p');
  
  % update the exp struct
  exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat);
end