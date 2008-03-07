function exp = pat_means(exp, params, patname, resDir)
%
%PAT_MEANS - for a given field in the events struct, calculate a
%mean over each unique value
%
% FUNCTION: exp = pat_means(exp, params, resDir, patname)
%
% INPUT: exp - struct created by init_iEEG or init_scalp
%        params - required fields: patname (specifies the name of
%                 which pattern in the exp struct to use)
%
%                 optional fields: eventFilter (specify subset of
%                 events to use), masks (cell array containing
%                 names of masks to apply to pattern), field (name
%                 of field of events struct to use in calculating mean -
%                 omit to average over all events)
%        resDir - 'mean' files are saved in resDir/data
%        patname - analysis name to save under in the exp struct
%
% OUTPUT: new exp struct with ana object added, which contains file
% info and parameters of the analysis
%

if ~isfield(params, 'patname')
  error('You must specify which pattern to use')
end
if ~exist('resDir', 'var')
  resDir = fullfile(exp.resDir, params.patname);
end
if ~exist('patname', 'var')
  patname = 'mean';
end

params = structDefaults(params, 'field', 'overall',  'overwrite', 0);

if ~exist(fullfile(resDir, 'data'), 'dir')
  mkdir(fullfile(resDir, 'data'));
end

files = {};
for s=1:length(exp.subj)
  fprintf('\n%s\n', exp.subj(s).id);
  
  pat1 = getobj(exp.subj(s), 'pat', params.patname);
  
  pat2.name = patname;
  pat2.file = fullfile(resDir, 'data', [exp.subj(s).id '_' patname '.mat']);
  pat2.params = params;
  pat2.dim = pat1.dim;
  
  % see if this subject has been done
  if ~params.overwrite
    if ~lockFile(pat2.file) | exist([pat1.file '.lock'], 'file')
      continue
    end
  end
  files = [files pat2.file];
  
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
  for j=1:length(vals)
    if iscell(vals)
      pat2.dim.event.label{j} = [params.field ' ' vals{j}];
    else
      pat2.dim.event.label{j} = [params.field ' ' num2str(vals(j))];
    end
  end
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
  if ~params.overwrite
    releaseFile(pat2.file);
  end
  subjpat(s) = pat2;
  
  load(exp.file);
  exp.subj(s) = setobj(exp.subj(s), 'pat', pat2);
  save(exp.file, 'exp');
end

% wait for all the individual subjects to finish
waitforfiles(files, 5000);

% create grand average pattern
pat2.file = fullfile(resDir, 'data', [patname '_ga.mat']);
load(exp.file);
exp = setobj(exp, 'pat', pat2);
save(exp.file, 'exp');

pattern = NaN(length(exp.subj), size(pattern,1), size(pattern,2), size(pattern,3), size(pattern,4));

% average across subjects
for s=1:length(subjpat)
  subj_pattern = loadPat(subjpat(s));
  pattern(s,:,:,:,:) = subj_pattern;
end

pattern = squeeze(mean(pattern,1));
save(pat2.file, 'pattern');
