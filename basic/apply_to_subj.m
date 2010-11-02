function subj = apply_to_subj(subj, fcn_handle, fcn_inputs, dist, varargin)
%APPLY_TO_SUBJ   Apply a function to all subjects.
%
%  subj = apply_to_subj(subj, fcn_handle, fcn_inputs, dist, ...)
%
%  Apply a function to each element of a subjects vector.
%
%  INPUTS:
%        subj:  a subject object or vector of subject objects.
%
%  fcn_handle:  a handle to a function of the form:
%                subj = fcn_handle(subj, ...)
%
%  fcn_inputs:  additional inputs to fcn_handle.
%
%        dist:  indicates how to evaluate the subjects:
%                0 - subjects are evaluated with a normal for loop
%                    (default)
%                1 - each subject is processed by a separate distributed
%                    task (requires the distributed computing engine;
%                    uses the default configuration)
%                2 - subjects are run in parallel using a parfor loop
%                    (to benefit from this, must have an open
%                    matlabpool)
%
%  OUTPUTS:
%        subj:  a subject vector.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   memory - memory requested for each job (dist=1 only). ('1G')
%
%  See also apply_to_subj_obj, apply_to_pat, apply_to_ev.

% input checks
if ~exist('subj','var')
  error('You must pass a subject structure.')
elseif ~exist('fcn_handle','var')
  error('You must pass a handle to a function.')
end
if ~exist('fcn_inputs','var')
  fcn_inputs = {};
end
if ~exist('dist','var')
  dist = 0;
end

% options
defaults.memory = '1G';
params = propval(varargin, defaults);

if dist==1
  % set up a scheduler
  if ~exist('~/runs', 'dir')
    mkdir('~/runs');
  end
  sm = findResource('scheduler', 'type', 'generic');
  set(sm, 'DataLocation', '~/runs');
  set(sm, 'SubmitFcn', {@sgeSubmitFcn2, params.memory});

  % create a job to run all subjects
  % use the current path, and override pathdef.m, jobStartup.m, etc.
  path_cell = regexp(path, ':', 'split');
  main_dir = fileparts(which('eeg_ana'));
  job_startup_file = fullfile(main_dir, 'utils', 'jobStartup.m');
  job_name = sprintf('apply_to_subj:%s', func2str(fcn_handle));
  job = createJob(sm, 'FileDependencies', {job_startup_file}, 'Name', job_name);
  job.PathDependencies = path_cell;

  % make a task for each subject
  for this_subj=subj
    name = get_obj_name(this_subj);
    createTask(job, fcn_handle, 1, {this_subj fcn_inputs{:}}, 'Name', name);
  end

  % capture command window output for all tasks (helpful for debugging)
  alltasks = get(job, 'Tasks');
  set(alltasks, 'CaptureCommandWindowOutput', true);

  % submit the job and wait for it to finish
  tic
  submit(job);
  fprintf('Job submitted.  Waiting for all tasks to finish...\n')
  
  wait(job);
  fprintf('apply_to_subj: job finished: %.2f seconds.\n', toc);

  % report any errors
  for i=1:length(job.tasks)
    task = job.tasks(i);
    if ~isempty(task.ErrorMessage)
      warning('eeg_ana:apply_to_subj:SubjError', ...
              '%s threw an error for subject %s:\n  %s', ...
              func2str(fcn_handle), task.Name, getReport(task.Error))
    end
  end

  % get a cell array of output arguments from each task
  fprintf('loading updated subjects...')
  temp = getAllOutputArguments(job);
  if isempty(temp)
    return
  end

  % convert to structure
  for i=1:length(temp)
    if isempty(temp{i})
      continue
    end
    subj = addobj(subj, temp{i});
  end
  fprintf('done.\n')
elseif dist==2
  % use parfor
  tic
  new_subj = [];
  parfor i=1:length(subj)
    if length(subj) > 1
      fprintf('%s\n', get_obj_name(subj(i)))
    end
    new_subj = [new_subj fcn_handle(subj(i), fcn_inputs{:})];
  end
  subj = new_subj;
  if length(subj) > 1
    fprintf('apply_to_subj: finished: %.2f seconds.\n', toc);
  end
else
  % run the function on each element of the subject vector
  tic
  for i=1:length(subj)
    this_subj = subj(i);
    if length(subj) > 1
      fprintf('%s\n', get_obj_name(this_subj))
    end
    % pass this subject as input to the function
    % and modify the subject vector
    subj = addobj(subj, fcn_handle(this_subj, fcn_inputs{:}));
  end
  if length(subj) > 1
    fprintf('apply_to_subj: finished: %.2f seconds.\n', toc);
  end
end
