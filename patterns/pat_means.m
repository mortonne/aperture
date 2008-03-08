function exp = pat_means(exp, params, patname, resDir)
%
%PAT_MEANS - for a given field in the events struct, calculate a
%mean over each unique value
%
% FUNCTION: exp = pat_means(exp, params, patname, resDir)
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

params = structDefaults(params, 'field', 'overall',  'grandAvg', 1,  'lock', 1,  'overwrite', 0);

files = {};
for s=1:length(exp.subj)
  fprintf('\n%s\n', exp.subj(s).id);
  
  % prepare the new pat object
  pat1 = getobj(exp.subj(s), 'pat', params.patname);
  
  pat2.name = patname;
  pat2.file = fullfile(resDir, 'data', [exp.subj(s).id '_' patname '.mat']);
  pat2.params = params;
  pat2.dim = pat1.dim;
  
  % check input files and prepare output files
  if prepFiles(pat1.file, pat2.file, params)~=0
    continue
  end
  files = [files pat2.file];
  
  % load pat and events with masks and filters applied
  [pattern1, events] = loadPat(pat1, params, 1);
  
  if strcmp(params.field, 'overall')
    vec = ones(1, length(events));
  else
    vec = getStructField(events, params.field);
  end
  
  % find the events corresponding to each condition
  vals = unique(vec);
  pat2.dim.event.num = length(vals);
  for j=1:length(vals)
    if iscell(vals)
      pat2.dim.event.label{j} = [params.field ' ' vals{j}];
      cond{j} = strcmp(vec, vals{j});
    else
      pat2.dim.event.label{j} = [params.field ' ' num2str(vals(j))];
      cond{j} = vec==vals(j);
    end
  end
  pat2.dim.event.vals = vals;
  
  % initialize the new pattern
  pattern = NaN(length(vals), size(pattern1,2), size(pattern1,3), size(pattern1,4));
  
  % average over the events in each condition
  for j=1:length(vals)
    pattern(j,:,:,:) = squeeze(nanmean(pattern1(cond{j},:,:,:),1));
  end
  
  % save the mean file for this subject
  closeFile(pat2.file, 'pattern');

  subjpat(s) = pat2;

  % update exp with the new pat object
  exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat2);
end

if params.grandAvg
  % wait for all the individual subjects to finish
  waitforfiles(files, 5000);
  
  pat2.file = fullfile(resDir, 'data', [patname '_ga.mat']);
  exp = update_exp(exp, 'pat', pat2);
  
  % initialize pattern to hold all subjects
  pattern = NaN(length(exp.subj), size(pattern,1), size(pattern,2), size(pattern,3), size(pattern,4));
  
  % get all subjects' means
  for s=1:length(subjpat)
    subj_pattern = loadPat(subjpat(s));
    pattern(s,:,:,:,:) = subj_pattern;
  end
  
  % average across subjects
  pattern = squeeze(mean(pattern,1));
  save(pat2.file, 'pattern');
end
