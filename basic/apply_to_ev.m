function subj = apply_to_ev(subj,ev_name,fcn_handle,fcn_inputs,dist)
%APPLY_TO_EV   Apply a function to an ev object for all subjects.
%
%  subj = apply_to_ev(subj, ev_name, fcn_handle, fcn_inputs, dist)
%  
%  INPUTS:
%        subj:  a [1 X N subjects] structure representing each subject in an
%               experiment.
%
%     ev_name:  the name of an ev object that has been created for at least
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

% input checks
if ~exist('subj','var')
  error('You must pass a subjects vector.')
  elseif ~exist('ev_name','var')
  error('You must specify the name of an events structure.')
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
subj = apply_to_subj(subj, @apply_to_obj, {'ev', ev_name, fcn_handle, fcn_inputs}, dist);
