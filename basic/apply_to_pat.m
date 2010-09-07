function subj = apply_to_pat(subj, pat_name, fcn_handle, fcn_inputs, ...
                             dist, varargin)
%APPLY_TO_PAT   Apply a function to a pat object for all subjects.
%
%  subj = apply_to_pat(subj, pat_name, fcn_handle, fcn_inputs, dist, ...)
%  
%  INPUTS:
%        subj:  a [1 X N subjects] structure representing each subject
%               in an experiment.
%
%    pat_name:  the name of a pat object that has been created for at
%               least one of the subjects in the subj vector.
%
%  fcn_handle:  a handle for a function of the form:
%                [pat, ...] = fcn(pat, ...)
%               If the name of the output pat object is different
%               from pat_name, a new object will be added to each
%               subject; otherwise, the existing object will be
%               overwritten.
%
%  fcn_inputs:  a cell array of additional inputs (after pat) to
%               fcn_handle.  If fcn_inputs = c, then fcn_handle will be
%               called with:
%                pat = fcn_handle(pat, c{1}, c{2}, ... c{end})
%
%        dist:  distributed evaluation; see apply_to_subj for possible
%               values.
%
%  OUTPUTS:
%        subj:  a modified subjects vector.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   memory - memory requested for each job (dist=1 only). ('1G')
%
%  See also apply_to_ev, apply_to_subj_obj, apply_to_subj.

% input checks
if ~exist('subj','var')
  error('You must pass a subjects vector.')
elseif ~exist('pat_name','var') || ~ischar(pat_name)
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

if strcmp(pat_name(end), '*')
  % find all patterns that begin with the input name
  pats = [subj.pat];
  pat_names = unique({pats.name});
  match = strmatch(pat_name(1:end-1), pat_names);
  pat_names = pat_names(match);
else
  pat_names = {pat_name};
end

for i=1:length(pat_names)
  % apply_to_subj_obj does all the work
  subj = apply_to_subj_obj(subj, {'pat', pat_names{i}}, fcn_handle, ...
                           fcn_inputs, dist, varargin{:});
end

