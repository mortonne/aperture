function subj = apply_to_pat(subj,pat_name,fcn_handle,varargin)
%APPLY_TO_PAT   Apply a function to a pat object for all subjects.
%
%  subj = apply_to_pat(subj, pat_name, fcn_handle, varargin)
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
%    varargin:  any additional arguments (i.e. varargin) become additional
%               inputs to fcn_handle.
%
%  OUTPUTS:
%        subj:  a modified subjects vector.
%
%  EXAMPLES:
%   % create a pattern for each subject
%   subj = applytosubj(subj, @create_pattern, {@sessVoltage, struct, 'volt_pat'});
%
%   % run an ANOVA on each pattern comparing recalled and not recalled events
%   params.fields = {'recalled'};
%   subj = apply_to_pat(subj, 'volt_pat', @pat_anovan, params, 'sme');

% run the function on each subject
subj = apply_to_subj(subj, @apply_to_obj, {'pat', pat_name, fcn_handle, varargin});
