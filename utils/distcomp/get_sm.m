function sm = get_sm(data_loc)
%GET_SM   Get the schedule manager.
%
%  Returns the scheduler used to scheduler toolbox jobs.
%
%  sm = get_sm(data_loc)

if nargin < 1
  data_loc = '~/runs';
end

% set up a scheduler
sm = parallel.cluster.Generic();
if ~exist(data_loc, 'dir')
  mkdir(data_loc);
end
set(sm, 'JobStorageLocation', data_loc)

% determine which resource manager is being used
jm = which_resource_manager;
if strcmp('none', jm)
  error('Job manager not found.')
end

% set SubmitFcn according to resource manager
if strcmp('SGE', jm)
  set(sm, 'IndependentSubmitFcn', {@independentSubmitFcn, params.memory});
  
elseif strcmp('TORQUE', jm)
  params.memory = torque_mem_format(params.memory);
  set(sm, 'IndependentSubmitFcn', {@independentSubmitFcn, params});
end
