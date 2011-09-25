function exp = apply_to_exp(exp, fcn_handle, fcn_inputs, varargin)
%APPLY_TO_EXP   Run a distributed job applying a function to an experiment.
%
%  exp = apply_to_exp(exp, fcn_handle, fcn_inputs, ...)
%
%  INPUTS:
%         exp:  experiment object.
%
%  fcn_handle:  handle to a function to apply to exp, of the form:
%                exp = fcn_handle(exp, ...)
%
%  fcn_inputs:  cell array of additional inputs to fcn_handle.
%
%  OUTPUTS:
%         exp:  experiment object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   memory   - amount of memory to request for the job. ('2G')
%   walltime - walltime to request for the job. ('00:15:00')
%   async    - if true, a job handle will be returned instead of exp,
%              and execution will not be halted to wait for the job to
%              finish. (false)

% options
defaults.memory = '2G';
defaults.walltime = '00:15:00';
defaults.async = false;
params = propval(varargin, defaults);

% set up a scheduler
sm = get_sm();

% determine which resource manager is being used
jm = which_resource_manager;
if strcmp('none', jm)
  error('Job manager not found.')
end

% set SubmitFcn according to resource manager
if strcmp('SGE', jm)
  set(sm, 'SubmitFcn', {@distributedSubmitFcn2, params.memory});
  
elseif strcmp('TORQUE', jm)
  params.memory = torque_mem_format(params.memory);
  set(sm, 'SubmitFcn', {@distributedSubmitFcn2, params});
end

% use the current path, and override pathdef.m, jobStartup.m, etc.
path_cell = regexp(path, ':', 'split');
main_dir = fileparts(which('eeg_ana'));
job_startup_file = fullfile(main_dir, 'utils', 'jobStartup.m');
job_name = sprintf('apply_to_subj:%s', func2str(fcn_handle));
job = createJob(sm, 'FileDependencies', {job_startup_file}, 'Name', job_name);
job.PathDependencies = path_cell;

task = createTask(job, fcn_handle, 1, {exp fcn_inputs{:}}, ...
                  'Name', exp.experiment);

% capture command window output for all tasks (helpful for debugging)
set(task, 'CaptureCommandWindowOutput', true);

% submit the job and wait for it to finish
submit(job);

if params.async
  exp = job;
  return
end
  
tic
fprintf('Job submitted.  Waiting for task to finish...\n')

wait(job);
fprintf('apply_to_exp: job finished: %.2f seconds.\n', toc);

% report any errors
for i = 1:length(job.tasks)
  task = job.tasks(i);
  if ~isempty(task.ErrorMessage)
    warning('eeg_ana:apply_to_exp:ExpError', ...
            '%s threw an error for experiment %s:\n  %s', ...
            func2str(fcn_handle), task.Name, getReport(task.Error))
  end
end

% get a cell array of output arguments from each task
fprintf('loading updated experiment...')
temp = getAllOutputArguments(job);
if isempty(temp)
  return
end

exp = temp{1};
fprintf('done.\n')

