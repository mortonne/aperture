function eeg = pat_means(eeg, params, resDir, patname)
%
%PAT_MEANS - for a given field in the events struct, calculate a
%mean over each unique value
%
% FUNCTION: eeg = pat_means(eeg, params, resDir, patname)
%
% INPUT: eeg - struct created by init_iEEG or init_scalp
%        params - required fields: patname (specifies the name of
%                 which pattern in the eeg struct to use)
%
%                 optional fields: eventFilter (specify subset of
%                 events to use), masks (cell array containing
%                 names of masks to apply to pattern), field (name
%                 of field of events struct to use in calculating mean -
%                 omit to average over all events)
%        resDir - 'mean' files are saved in resDir/data
%        patname - analysis name to save under in the eeg struct
%
% OUTPUT: new eeg struct with ana object added, which contains file
% info and parameters of the analysis
%

if ~exist('patname', 'var')
  patname = 'mean';
end
if ~isfield(params, 'patname')
  error('You must specify which pattern to use')
end

params = structDefaults(params, 'field', 'overall');

if ~exist(fullfile(resDir, 'data'), 'dir')
  mkdir(fullfile(resDir, 'data'));
end

files = cell(length(eeg.subj),1);
for s=1:length(eeg.subj)
  fprintf('\n%s\n', eeg.subj(s).id);
  
  pat1 = getobj(eeg.subj(s), 'pat', params.patname);
  
  pat2.name = patname;
  pat2.file = fullfile(resDir, 'data', [eeg.subj(s).id '_' patname '.mat']);
  pat2.params = params;
  pat2.dim = pat1.dim;
  
  % see if this subject has been done
  if ~lockFile(pat2.file) | exist([pat1.file '.lock'], 'file')
    continue
  end
  
  % load pat and events with masks and filters applied
  [pattern1, events] = loadPat(pat1, params, 1);
  
  if strcmp(params.field, 'overall')
    vec = ones(1, length(events));
  else
    vec = getStructField(events, params.field);
  end
  
  % get mean values for each regressor
  vals = unique(vec);
  pat2.dim.event.num = length(vals);
  pat2.dim.event.label = params.field;
  pat2.dim.event.vals = vals;
  
  pattern = NaN(length(vals), size(pattern1,2), size(pattern1,3), size(pattern1,4));
  
  for j=1:length(vals)
    if iscell(vals)
      thiscond = strcmp(vec, vals{j});
    else
      thiscond = vec==vals(j);
    end
    pattern(j,:,:,:) = squeeze(nanmean(pattern1(thiscond,:,:,:),1));
  end
  
  % save the mean file for this subject
  save(pat2.file, 'pattern');
  releaseFile(pat2.file);
  subjpat(s) = pat2;
  
  load(eeg.file);
  eeg.subj(s) = setobj(eeg.subj(s), 'pat', pat2);
  save(eeg.file, 'eeg');
end

% wait for all the individual subjects to finish
waitforfiles(files, 5000);

% create grand average pattern
pat2.file = fullfile(resDir, 'data', [patname '_ga.mat']);
load(eeg.file);
eeg = setobj(eeg, 'pat', pat2);
save(eeg.file, 'eeg');

pattern = NaN(length(eeg.subj), size(pattern,1), size(pattern,2), size(pattern,3), size(pattern,4));

% average across subjects
for s=1:length(subjpat)
  subj_pattern = loadPat(subjpat(s));
  pattern(s,:,:,:,:) = subj_pattern;
end

pattern = squeeze(mean(pattern,1));
save(pat2.file, 'pattern');
