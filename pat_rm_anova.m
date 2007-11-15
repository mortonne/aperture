function eeg = pat_rm_anova(eeg, resDir, regressors, masks)
%
%PAT_RM_ANOVA - calculates an n-way ANOVA across subjects
%
% FUNCTION: eeg = pat_rm_anova(eeg, resDir, regressors, masks)
%
% INPUT: eeg - struct created by running init_scalp; eeg.params
%        must contain a field 'field' that has the name of each
%        field in the events struct to be used as a regressor
% 
% OUTPUT: power values with significance, saved by channel in
%         'eeg.resDir/'
%

if ~exist('masks', 'var')
  masks = {};
end

params = eeg.params;
eeg.resDir = resDir;

if ~exist(fullfile(eeg.resDir, 'data'), 'dir')
  mkdir(fullfile(eeg.resDir, 'data'));
end

fprintf(['\nStarting Repeated Measures ANOVA:\n']);

% step through channels
for c=1:length(eeg.chan)
  fprintf('\nLoading patterns for channel %d: ', eeg.chan(c).number);
  
  eeg.statFile{c} = fullfile(eeg.resDir, 'data', ['chan' num2str(eeg.chan(c).number) '_rm_anova.mat']);
  if ~lockFile(eeg.statFile{c})
    save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');
    continue
  end
  
  chan_pats = []; 
  tempsubj_reg = [];
  tempgroup = cell(1,length(regressors));
  
  % concatenate subjects
  for s=1:length(eeg.subj)
    fprintf('%s ', eeg.subj(s).id);
    pat = loadPat(eeg.subj(s).patFile, masks);
    load(eeg.subj(s).regFile);
    
    reg = filterStruct(reg, 'ismember(name, varargin{1})', regressors);
    for i=1:length(reg)
      tempgroup{i} = [tempgroup{i}; reg(i).vec'+1];
    end
    
    tempsubj_reg = [tempsubj_reg; ones(size(pat.mat,1),1)*s];
    chan_pats = cat(1, chan_pats, squeeze(pat.mat(:,c,:,:)));
  end
  fprintf('\n');
  
  % initialize the stat struct
  fprintf('ANOVA: ');
  stat(1).name = regressors{1};
  stat(2).name = regressors{2};
  stat(3).name = [regressors{1} 'X' regressors{2}];
  stat(4).name = 'subject';
  for i=1:length(stat)
    stat(i).p = NaN(size(chan_pats,2), size(chan_pats,3));
  end
  
  for b=1:size(chan_pats,2)
    fprintf(' %dms ', params.binMS{b}(1));
    
    for f=1:size(chan_pats,3)
      if isfield(params, 'binFreq')
	fprintf('%.2f ', params.binFreq{f}(1));
      end
      
      % remove NaNs
      thispat = squeeze(chan_pats(:,b,f));
      good = ~isnan(thispat);
      thispat = thispat(good);
      for i=1:length(tempgroup)
	group{i} = tempgroup{i}(good);
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
    if isfield(params, 'binFreq')
      fprintf('\n');
    end
  end % bin
  fprintf('\n');
  
  save(eeg.statFile{c}, 'stat');
  releaseFile(eeg.statFile{c});
  save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');
  
end % channel


