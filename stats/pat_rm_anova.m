function exp = pat_rm_anova(exp, params, statname, resdir)
%PAT_RM_ANOVA   Test for significance across subjects.
%   EXP = PAT_RM_ANOVA(EXP,PARAMS,STATNAME,RESDIR) runs a
%   statistical test specified by the PARAMS struct across
%   all subjects in EXP. The results are saved in a stat
%   object named STATNAME, which points to a file in resdir
%   (default: exp.resDir/'eeg'/params.patname/'stats').
%
%   Params:
%     'patname'   specifies which pattern to use from each subject
%     'test'      string identifying which statistical test
%                 to use ('anovan','RMAOV1', or 'RMAOV2')
%     'testinput' cell array of additional inputs to the test
%                 function
%     'overwrite' if true (default), existing stat.file will
%                 be overwritten
%
%   The stat object is attached to an exp pat object with
%   the same name as params.patname. If the pat object
%   doesn't exist yet, it is created.
%

if ~isfield(params, 'fields')
  error('You must specify how to create regressors');
end
if ~iscell(params.fields)
  params.fields = {params.fields};
end
if ~exist('resdir', 'var')
  resdir = fullfile(exp.resDir, 'eeg', params.patname);
end

params = structDefaults(params, 'patname','', 'test','RMAOV1', 'testinput',{}, 'overwrite',1);
warning('off','all')

% get pat objects from all subjects
fprintf('creating regressors...')
group = cell(1,length(params.fields)+1);
s = 1;
for subj=exp.subj
  if ~ismember(params.patname,{subj.pat.name})
    % this subject doesn't have the pattern we want
    continue
  end
  subjpat(s) = getobj(subj,'pat',params.patname);

  % create the regressors
  load(subjpat(s).dim.ev.file);
  for i=1:length(params.fields)
    group{i} = [group{i}; binEventsField(events, params.fields{i})'];
  end
  group{end} = [group{end}; ones(subjpat(s).dim.ev.len,1)*s];
  s = s + 1;
end

if isfield(exp,'pat') && ~isempty(exp.pat) && ismember(params.patname, {exp.pat.name})
  % if the corresponding across-subject pattern exists, attach stat to that
  pat = getobj(exp,'pat',params.patname);
  else
  % create a blank pat object that will hold the new stat
  pat = init_pat(params.patname,'','',struct,subjpat(1).dim);
  pat.source = exp.experiment;
end

% create a stat object
filename = sprintf('%s_%s_%s.mat', pat.name, statname, exp.experiment);
statfile = fullfile(resdir, 'stats', filename);
stat = init_stat(statname,statfile,params);

% update the exp struct
pat = setobj(pat,'stat',stat);
exp = update_exp(exp,'pat',pat);

% check input and prepare output files
err = prepFiles({}, stat.file, params);
if err
  error('I/O problem.')
end

fprintf('running %s...\n', params.test)
%fprintf(['\nStarting Repeated Measures ANOVA:\n']);

% step through channels
psize = patsize(pat.dim);
nfact = length(params.fields)+1;
p = NaN(nfact,psize(2),psize(3),psize(4));
fprintf('Channel: ');
for c=1:psize(2)
  %fprintf('\nLoading patterns for channel %d: ', pat.dim.chan(c).label);
  fprintf('%s', pat.dim.chan(c).label);
  
  % concatenate subjects
  pattern = [];
  for thispat=subjpat
    % load the pattern for this channel
    chanpat = load_pattern(thispat,struct('patnum',c));
    pattern = cat(1, pattern, chanpat);
  end

  % run the statistic
  for t=1:size(pattern,3)
    if ~mod(t,floor(size(pattern,3)/4))
      fprintf('.')
    end
    for f=1:size(pattern,4)
      p(:,c,t,f) = run_sig_test(squeeze(pattern(:,:,t,f)),group,params.test,params.testinput{:});
    end
  end

end % channel
if all(isnan(p(:)))
  error('Problem with sig test; p values are all NaNs.')
end

save(stat.file, 'p');
closeFile(stat.file);
