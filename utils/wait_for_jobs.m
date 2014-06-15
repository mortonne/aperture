function wait_for_jobs(jobs, refresh)
%WAIT_FOR_JOB   Wait for a set of jobs to finish.
%
%  wait_for_jobs(jobs, refresh)
%
%  INPUTS:
%     jobs:  vector of job handles.
%
%  refresh:  seconds to pause between checking job status. Setting to
%            check less often will reduce the load on the scheduler.
%            Default is 2.

if nargin < 2
  refresh = 2;
end

finished = false;
first = false;
while ~finished
  if ~first
    pause(refresh)
  else
    first = false;
  end
  
  job_finished = false(1, length(jobs));
  for i = 1:length(jobs)
    job_finished(i) = strcmp(jobs.State, 'finished');
  end
  finished = all(job_finished);
end


