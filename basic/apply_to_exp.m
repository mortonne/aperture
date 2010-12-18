function exp = apply_to_exp(exp, fcn_handle, fcn_inputs, memory)
%APPLY_TO_EXP
%
%  exp = apply_to_exp(exp, fcn_handle, fcn_inputs, memory)

if ~exist('memory', 'var')
  memory = '2g';
end

% set up a scheduler
if ~exist('~/runs', 'dir')
  mkdir('~/runs');
end
sm = findResource('scheduler', 'type', 'generic');
set(sm, 'DataLocation', '~/runs');
set(sm, 'SubmitFcn', {@sgeSubmitFcn2, memory});

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
tic
submit(job);
fprintf('Job submitted.  Waiting for all tasks to finish...\n')

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

