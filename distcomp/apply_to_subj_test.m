function subj = apply_to_subj_test(subj,fcn_handle,fcn_inputs)
%APPLYTOSUBJ   Apply a function to all subjects.
%
%  subj = apply_to_subj_test(subj, fcn_handle, fcn_inputs)
%
%  Same as apply_to_subj, but not distributed. Useful for debugging
%  code before using the distributed version.

% create a job to run all subjects
for s=1:length(subj)
  fprintf('%s\n', subj(s).id)
  
  % run the function to modify this subject
  subj(s) = fcn_handle(subj(s), fcn_inputs{:});
end
