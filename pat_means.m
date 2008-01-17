function eeg = pat_means(eeg, params, resDir, ananame)
%
%PAT_MEANS - for a given field in the events struct, calculate a
%mean over each unique value
%
% FUNCTION: eeg = pat_means(eeg, params, resDir, ananame)
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
%        ananame - analysis name to save under in the eeg struct
%
% OUTPUT: new eeg struct with ana object added, which contains file
% info and parameters of the analysis
%

if ~exist('ananame', 'var')
  ananame = 'mean';
end
if ~isfield(params, 'patname')
  error('You must specify which pattern to use')
end

params = structDefaults(params, 'eventFilter', '',  'masks', {},  'field', 'overall');

if ~exist(fullfile(resDir, 'data'), 'dir')
  mkdir(fullfile(resDir, 'data'));
end

% write all file info and update the eeg struct
for s=1:length(eeg.subj)
  ana.name = ananame;
  ana.file = fullfile(resDir, 'data', [eeg.subj(s).id '_' ananame '.mat']);
  ana.pat = getobj(eeg.subj(s), 'pat', params.patname);
  ana.params = params;
  
  eeg.subj(s) = setobj(eeg.subj(s), 'ana', ana);
end
save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');

for s=1:length(eeg.subj)
  fprintf('\n%s\n', eeg.subj(s).id);
  
  ana = getobj(eeg.subj(s), 'ana', ananame);
  
  % see if this subject has been done
  if ~lockFile(ana.file) | exist([ana.pat.file '.lock'], 'file')
    continue
  end
  
  % load pat and events with masks and filters applied
  pattern = loadPat(ana.pat.file, params.masks, ana.pat.eventsFile, params.eventFilter);
  events = loadEvents(ana.pat.eventsFile, ana.pat.params.replace_eegFile);
  events = filterStruct(events, params.eventFilter);
  
  if strcmp(params.field, 'overall')
    vec = ones(1, length(events));
  else
    vec = getStructField(events, params.field);
  end
  
  % get mean values for each regressor
  mean.name = params.field;
  mean.vals = unique(vec);
  mean.mat = NaN(length(mean.vals), size(pattern,2), size(pattern, 3), size(pattern, 4));
  for j=1:length(mean.vals)
    if iscell(mean.vals)
      thiscond = strcmp(vec, mean.vals{j});
    else
      thiscond = vec==mean.vals(j);
    end
    mean.mat(j,:,:,:) = squeeze(nanmean(pattern(thiscond,:,:,:),1));
  end
  
  % save the mean file for this subject
  save(ana.file, 'mean');
  releaseFile(ana.file);
  
end