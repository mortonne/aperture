function jobStartup(job)
% JOBSTARTUP Perform user-specific job startup actions.
%
%   jobStartup(job)
%
%   To define specific job initialization actions on each worker
%   that participates in a job, you can do any of the following:
%   1. Add M-code that performs those actions to this file for each worker.
%   2. Add to the job's PathDependencies property a directory that
%      contains a file named jobStartup.m.
%   3. Include a file named jobStartup.m in the job's FileDependencies
%      property.
%
%   The file in FileDependencies takes precendence over the
%   PathDependencies file, which takes precedence over this file on
%   the worker's installation.
%
%   The job parameter passed to this function is the job object
%   for which the worker is about to execute a task.
%
%   If this function throws an error, the error information appears in the task's
%   ErrorMessage and ErrorIdentifier properties, and the task will not be
%   executed.  If running this function for the first task results in
%   an error, this worker will attempt to run subsequent tasks without
%   running the jobStartup function again.
%
%   Any path changes made here or during the execution of tasks will be
%   reverted by the MATLAB Distributed Computing Server to their original
%   values before the next job runs.  Any data stored by this function or
%   by the execution of this job's tasks (for example, in the base workspace
%   or in global or persistent variables) will not be cleared by the MATLAB
%   Distributed Computing Server before the next job runs, unless the
%   RestartWorker property of the next job is set to true.
%
%   See also taskStartup, taskFinish.
