function subj_out = apply_to_subj(subj,fcn_handle,fcn_inputs)
%APPLYTOSUBJ   Apply a function to all subjects using Distributed Computing Toolbox.
%
%  subj = apply_to_subj(subj, fcn_handle, fcn_inputs)
%
%  Applies a function to each element of a subj vector. The function is
%  evaluated with all subjects in parallel.
%
%  INPUTS:
%        subj:  vector structure representing one or more subjects.
%
%  fcn_handle:  handle to a function that takes one subj as its first input,
%               add returns subj as its first output.
%
%  fcn_inputs:  additional inputs to fcn_handle.
%
%  OUTPUTS:
%        subj:  modified subj structure.

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
