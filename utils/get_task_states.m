function counts = get_task_states(jobs)
%GET_TASK_STATES   Get the states of all tasks in a set of jobs.
%
%  counts = get_task_states(jobs)
%
%  INPUTS:
%     jobs:  vector of job handles.
%
%  OUTPUTS:
%   counts:  Vector with the number of tasks in each of the possible
%            states, in the order: pending, queued, running, finished.

states = {'pending' 'queued' 'running' 'finished'};
counts = zeros(1, 4);

if isempty(jobs)
  return
end

for i = 1:length(jobs)
  for j = 1:length(jobs.Tasks)
    ind = find(strcmp(states, jobs.Tasks(i).State));
    counts(ind) = counts(ind) + 1;
  end
end
