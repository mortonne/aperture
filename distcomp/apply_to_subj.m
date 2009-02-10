function subj_out = apply_to_subj(subj,fcn_handle,fcn_inputs)
%APPLYTOSUBJ   Apply a function to all subjects using Distributed Computing Toolbox.
%   SUBJ = APPLY_TO_SUBJ(SUBJ,FUNCTION_HANDLE) runs the function represented by
%   FUNCTION_HANDLE on each element of the SUBJ vector. Each subject is evaluated
%   on a different node.
%
%   The function can modify each subj in any way, as long as all returned subjs
%   have the same number and order of fields. The modified subj vector is returned.

% get the default job manager/scheduler
sm = findResource();

% create a job to run all subjects
job = createJob(sm);
for this_subj=subj
  % make a task to run this subject
  createTask(job, fcn_handle, 1, {this_subj fcn_inputs{:}});
end

% capture command window output for all tasks
alltasks = get(job, 'Tasks');
set(alltasks, 'CaptureCommandWindowOutput', true);

% submit the job and wait for it to finish
tic
submit(job);
wait(job);
fprintf('apply_to_subj: job finished: %d seconds.\n', toc);

% get a cell array of output arguments from each task
temp = getAllOutputArguments(job);

% convert to structure
for i=1:length(temp)
  subj_out(i) = temp{i};
end
