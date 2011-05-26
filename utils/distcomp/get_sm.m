function sm = get_sm()
%GET_SM   Get the schedule manager.
%
%  Returns the scheduler used to scheduler toolbox jobs.
%
%  sm = get_sm()

% set up a scheduler
sm = findResource('scheduler', 'type', 'generic');
if ~exist('~/runs', 'dir')
  mkdir('~/runs');
end
set(sm, 'DataLocation', '~/runs')

