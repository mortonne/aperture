function subj = apply_to_pat(subj, pat_name, fcn_handle, fcn_inputs, dist)
%APPLY_TO_PAT   Apply a function to a pat object for all subjects.
%
%  subj = apply_to_pat(subj, pat_name, fcn_handle, fcn_inputs, dist)
%  
%  INPUTS:
%        subj:  a [1 X N subjects] structure representing each subject
%               in an experiment.
%
%    pat_name:  the name of a pat object that has been created for at
%               least one of the subjects in the subj vector.
%
%  fcn_handle:  a handle for a function that takes a pat object as first
%               input, and outputs a pat object.
%
%  fcn_inputs:  a cell array of additional inputs (after pat) to
%               fcn_handle.
%
%        dist:  distributed evaluation; see apply_to_subj for possible
%               values.
%
%  OUTPUTS:
%        subj:  a modified subjects vector.
%
%  EXAMPLES:
%   % create a pattern for each subject
%   subj = apply_to_subj(subj, @create_pattern, {@sessVoltage, struct, 'volt_pat'});
%
%   % run an ANOVA on each pattern comparing recalled and not recalled
%   % events
%   params.fields = {'recalled'};
%   subj = apply_to_pat(subj, 'volt_pat', @pat_anovan, {params, 'sme'});
%
%  See also apply_to_ev, apply_to_subj_obj, apply_to_subj.

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

% apply_to_subj_obj does all the work
subj = apply_to_subj_obj(subj, {'pat', pat_name}, fcn_handle, fcn_inputs, dist);

