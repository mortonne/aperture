function eeg = pat_means(eeg, resDir, regressors, masks, overall)
%eeg = pat_means(eeg, resDir, regressors, masks, overall)

if ~exist('overall', 'var')
  overall = 1;
end

if ~exist(fullfile(resDir, 'data'), 'dir')
  mkdir(fullfile(resDir, 'data'));
end

eeg.resDir = resDir;

for s=1:length(eeg.subj)
  fprintf('\n%s\n', eeg.subj(s).id);
  
  eeg.subj(s).meansFile = fullfile(resDir, 'data', [eeg.subj(s).id '_means.mat']);
  
  if ~lockFile(eeg.subj(s).meansFile)
    save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');
    continue
  end
  
  pat = loadPat(eeg.subj(s).patFile, masks);
  load(eeg.subj(s).regFile);
  
  reg = filterStruct(reg, 'ismember(name, varargin{1})', regressors);
  
  % get mean values for each regressor
  for i=1:length(reg)
    means(i).name = reg(i).name;
    means(i).vals = unique(reg(i).vec);    
    means(i).mat = NaN(length(means(i).vals), size(pat.mat,2), size(pat.mat, 3), size(pat.mat, 4));
    for j=1:length(means(i).vals)
      if iscell(means(i).vals)
	thiscond = strcmp(reg(i).vec, means(i).vals{j});
      else
	thiscond = reg(i).vec==means(i).vals(j);
      end
      means(i).mat(j,:,:,:) = squeeze(nanmean(pat.mat(thiscond,:,:,:),1));
    end
    
  end
  
  if overall
    means(i+1).name = 'overall';
    means(i+1).vals = 'N/A';
    means(i+1).mat(1,:,:) = squeeze(nanmean(pat.mat, 1));
  end
  
  save(eeg.subj(s).meansFile, 'means');
  releaseFile(eeg.subj(s).meansFile);
  save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');
  
end