function subj = apply_to_pat(subj,pat_name,fcn_handle,fcn_inputs,dist)
%APPLY_TO_PAT   Apply a function to a pat object for all subjects.
%
%  subj = apply_to_pat(subj, pat_name, fcn_handle, fcn_inputs, dist)
%  
%  INPUTS:
%        subj:  a [1 X N subjects] structure representing each subject in an
%               experiment.
%
%    pat_name:  the name of a pat object that has been created for at least
%               one of the subjects in the subj vector.
%
%  fcn_handle:  a handle for a function that takes a pat object as first input,
%               and outputs a pat object.
%
%  fcn_inputs:  a cell array of additional inputs (after pat) to fcn_handle.
%
%        dist:  if true, subjects will be evaluated in distributed tasks.
%               Default: false
%
%  OUTPUTS:
%        subj:  a modified subjects vector.
%
%  EXAMPLES:
%   % create a pattern for each subject
%   subj = apply_to_subj(subj, @create_pattern, {@sessVoltage, struct, 'volt_pat'});
%
%   % run an ANOVA on each pattern comparing recalled and not recalled events
%   params.fields = {'recalled'};
%   subj = apply_to_pat(subj, 'volt_pat', @pat_anovan, {params, 'sme'});

% input checks
if ~exist('subj','var')
  error('You must pass a subjects vector.')
elseif ~exist('pat_name','var')
  error('You must specify the name of a pattern.')
elseif ~exist('fcn_handle','var')
  error('You must pass a handle to a function.')
end
if ~exist('fcn_inputs','var')
  fcn_inputs = {};
end
if ~exist('dist','var')
  dist = false;
end

% run the function on each subject
if ~dist
  % use apply_to_subj the standard way, so we can see subject ID get 
  % printed out
  subj = apply_to_subj(subj, @apply_to_obj, ...
                      {'pat', pat_name, fcn_handle, fcn_inputs}, dist);
else
  % export pattern objects first, so there is less to send to each worker
  pats = getobjallsubj(subj, {'pat', pat_name});
  
  % name will not be unique, but source will
  sources = {pats.source};
  [pats.name] = deal(sources{:});
  
  % run as though the pat objects were subj objects
  pats = apply_to_subj(pats, fcn_handle, fcn_inputs, dist);
  
  % fix the name field
  [pats.name] = deal(pat_name);
  
  % put the updated pattern objects back on the subjects
  for i=1:length(subj)
    subj(i) = setobj(subj(i), 'pat', pats(i));
  end
end
