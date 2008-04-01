function exp = pat_rm_anova(exp, params, patname, resDir)
%
%PAT_RM_ANOVA - calculates a 2-way ANOVA across subjects, using two
%fields from the events struct as regressors
%
% FUNCTION: exp = pat_rm_anova(exp, params, patname, resDir)
%
% INPUT: exp - struct created by init_iEEG or init_scalp
%        params - required fields: patname (specifies the name of
%                 which pattern in the exp struct to use), fields
%                 (specifies which fields of the events struct to
%                 use as regressors)
%
%                 optional fields: eventFilter (specify subset of
%                 events to use), masks (cell array containing
%                 names of masks to apply to pattern)
%        resDir - 'stat' files are saved in resDir/data
%        patname - analysis name to save under in the exp struct
%
% OUTPUT: new exp struct with ana object added, which contains file
% info and parameters of the analysis
%

if ~isfield(params, 'patname')
  error('You must specify which pattern to use')
end
if ~isfield(params, 'fields')
  error('You must specify two fields to use as regressors');
end
if ~exist('resDir', 'var')
  resDir = fullfile(exp.resDir, params.patname);
end
if ~exist('patname', 'var')
  patname = 'RMAOV2';
end

params = structDefaults(params, 'eventFilter', '',  'masks', {},  'lock', 1,  'overwrite', 0);

% get pat objects from all subjects
for s=1:length(exp.subj)
  try
    subjpat(s) = getobj(exp.subj(s), 'pat', params.patname);
  catch
    continue
  end
end

% write the filenames for each piece of the final pattern
for c=1:length(subjpat(1).dim.chan)
  patfile{c} = fullfile(resDir, 'data', [patname '_chan' subjpat(1).dim.chan(c).label '.mat']);
end

% update the events dimension
ev.file = fullfile(resDir, 'data', [patname '_events.mat']);
ev.length = 4;

events(1).type = params.fields{1};
events(2).type = params.fields{2};
events(3).type = [params.fields{1} 'X' params.fields{2}];
events(4).type = 'subject';
save(ev.file, 'events');

chan = subjpat(1).chan;
time = subjpat(1).time;
freq = subjpat(1).freq;

% create the new across subject pat object
pat = init_pat(patname, patfile, params, ev, chan, time, freq);

% update the exp struct
exp = update_exp(exp, 'pat', pat);

fprintf(['\nStarting Repeated Measures ANOVA:\n']);

% step through channels
for c=1:length(chan)
  fprintf('\nLoading patterns for channel %d: ', chan(c).label);

  % check input and prepare output files
  if prepFiles({}, pat.file{c}, params)~=0
    continue
  end
  
  chan_pats = [];
  tempgroup = cell(1,length(params.fields)+1);
  
  % concatenate subjects
  for s=1:length(exp.subj)
    fprintf('%s ', exp.subj(s).id);
    
    [pattern, events] = loadPat(subjpat(s).file, params, 1);
    
    for i=1:length(params.fields)
      tempgroup{i} = [tempgroup{i}; getStructField(events, params.fields{i})'];
    end
    tempgroup{i+1} = [tempgroup{i+1}; ones(size(pattern,1),1)*s];

    chan_pats = cat(1, chan_pats, squeeze(pattern(:,c,:,:)));
  end
  fprintf('\n');
  
  % initialize the pattern that will hold p-values
  fprintf('ANOVA: ');
  pattern = NaN(ev.length, 1, length(time), length(freq));
  
  for t=1:size(chan_pats,2)
    fprintf(' %s ', time(t).label);
    
    for f=1:size(chan_pats,3)
      if ~isempty(freq)
	fprintf('%s ', freq(f).label);
      end
      
      % remove NaNs
      thispat = squeeze(chan_pats(:,t,f));
      good = ~isnan(thispat);
      if length(good)==0
	continue
      end
      thispat = thispat(good);
      
      % fix regressors
      for i=1:length(tempgroup)
	group{i} = tempgroup{i}(good);
	vals = unique(group{i});
	for j=1:length(vals)
	  group{i}(group{i}==vals(j)) = j;
	end
      end
      
      % do a two-way rm anova
      p = RMAOV2_mod([thispat group{1} group{2} group{3}], 0.05, 0);
      for e=1:length(p)
	pattern(e,1,t,f) = p(e);
      end
      
      % if two cats, get the direction of the effect
      for e=1:2
	cats = unique(group{e});
	if length(cats)==2
	  if mean(thispat(group{e}==cats(1))) < mean(thispat(group{e}==cats(2)))
	    pattern(e,1,t,f) = -pattern(e,1,t,f);
	  end
	end
      end
      
    end % freq
    if ~isempty(freq)
      fprintf('\n');
    end
  end % bin
  fprintf('\n');
  
  % release and save
  closeFile(pat.file{c}, 'pattern');
end % channel


