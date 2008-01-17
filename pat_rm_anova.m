function eeg = pat_rm_anova(eeg, params, resDir, ananame)
%
%PAT_RM_ANOVA - calculates a 2-way ANOVA across subjects, using two
%fields from the events struct as regressors
%
% FUNCTION: eeg = pat_rm_anova(eeg, params, resDir, ananame)
%
% INPUT: eeg - struct created by init_iEEG or init_scalp
%        params - required fields: patname (specifies the name of
%                 which pattern in the eeg struct to use), fields
%                 (specifies which fields of the events struct to
%                 use as regressors)
%
%                 optional fields: eventFilter (specify subset of
%                 events to use), masks (cell array containing
%                 names of masks to apply to pattern)
%        resDir - 'stat' files are saved in resDir/data
%        ananame - analysis name to save under in the eeg struct
%
% OUTPUT: new eeg struct with ana object added, which contains file
% info and parameters of the analysis
%

if ~exist('ananame', 'var')
  ananame = 'RMAOV2';
end
if ~isfield(params, 'fields')
  error('You must specify two fields to use as regressors');
end

params = structDefaults(params, 'eventFilter', '',  'masks', {});

if ~exist(fullfile(resDir, 'data'), 'dir')
  mkdir(fullfile(resDir, 'data'));
end

% write all file info
ana.name = ananame;
ana.file = {};
for s=1:length(eeg.subj)
  ana.pat(s) = getobj(eeg.subj(s), 'pat', params.patname);
end
channels = ana.pat(1).params.channels;
for c=1:length(channels)
  ana.file{c} = fullfile(resDir, 'data', [ananame '_chan' num2str(channels(c)) '.mat']);
end
ana.params = params;

% update the eeg struct
eeg = setobj(eeg, 'ana', ana);
save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');

fprintf(['\nStarting Repeated Measures ANOVA:\n']);

% step through channels
for c=1:length(channels)
  fprintf('\nLoading patterns for channel %d: ', channels(c));
  
  if ~lockFile(ana.file{c})
    continue
  end
  
  chan_pats = []; 
  tempsubj_reg = [];
  tempgroup = cell(1,length(params.fields));
  
  % concatenate subjects
  for s=1:length(eeg.subj)
    fprintf('%s ', eeg.subj(s).id);
    pat = ana.pat(s);
    
    pattern = loadPat(pat.file, params.masks, pat.eventsFile, params.eventFilter);
    events = loadEvents(pat.eventsFile, pat.params.replace_eegFile);
    events = filterStruct(events, params.eventFilter);
    
    for i=1:length(params.fields)
      tempgroup{i} = [tempgroup{i}; getStructField(events, params.fields{i})'];
    end
    
    tempsubj_reg = [tempsubj_reg; ones(size(pattern,1),1)*s];
    chan_pats = cat(1, chan_pats, squeeze(pattern(:,c,:,:)));
  end
  fprintf('\n');
  
  % initialize the stat struct
  fprintf('ANOVA: ');
  stat(1).name = params.fields{1};
  stat(2).name = params.fields{2};
  stat(3).name = [params.fields{1} 'X' params.fields{2}];
  stat(4).name = 'subject';
  for i=1:length(stat)
    stat(i).p = NaN(size(chan_pats,2), size(chan_pats,3));
  end
  
  for b=1:size(chan_pats,2)
    fprintf(' %dms ', pat.params.binMS{b}(1));
    
    for f=1:size(chan_pats,3)
      if isfield(pat.params, 'binFreq')
	fprintf('%.2f ', pat.params.binFreq{f}(1));
      end
      
      % remove NaNs
      thispat = squeeze(chan_pats(:,b,f));
      good = ~isnan(thispat);
      thispat = thispat(good);
      for i=1:length(tempgroup)
	group{i} = tempgroup{i}(good);
	vals = unique(group{i});
	if vals(1)==0
	  group{i} = group{i} + 1;
	end
      end
      subj_reg = tempsubj_reg(good);
      
      % fix the subject regressor numbers
      subjs = unique(subj_reg);
      for s=1:length(subjs)
	subj_reg(subj_reg==subjs(s)) = s;
      end
      
      % do a two-way rm anova
      p = RMAOV2_mod([thispat group{1} group{2} subj_reg], 0.05, 0);
      for i=1:length(p)
	stat(i).p(b,f) = p(i);
      end
      
      % if two cats, get the direction of the effect
      for i=1:2
	cats = unique(group{i});
	if length(cats)==2
	  if mean(thispat(group{i}==cats(1))) < mean(thispat(group{i}==cats(2)))
	    stat(i).p(b,f) = -stat(i).p(b,f);
	  end
	end
      end
      
    end % freq
    if isfield(pat.params, 'binFreq')
      fprintf('\n');
    end
  end % bin
  fprintf('\n');
  
  save(ana.file{c}, 'stat');
  releaseFile(ana.file{c});
  
end % channel


