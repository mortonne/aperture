function subj = apply_to_subj(subj,fcn_handle,fcn_inputs,dist)
%APPLY_TO_SUBJ   Apply a function to all subjects.
%
%  subj = apply_to_subj(subj, fcn_handle, fcn_inputs, dist)
%
%  Apply a function to each element of a subjects vector.
%
%  INPUTS:
%        subj:  a subject object or vector of subject objects.
%
%  fcn_handle:  a handle to a function of the form:
%               subj = fcn_handle(subj, ...)
%
%  fcn_inputs:  additional inputs to fcn_handle.
%
%        dist:  indicates how to evaluate the subjects:
%               0 - subjects are evaluated with a normal for 
%                   loop (default)
%               1 - each subject is processed by a separate
%                   distributed task (requires the distributed
%                   computing engine; uses the default configuration)
%               2 - subjects are run in parallel using a parfor
%                   loop (to benefit from this, must have an open
%                   matlabpool)
%
%  OUTPUTS:
%        subj:  a subject vector.
%
%  See also apply_to_obj, apply_to_pat, apply_to_ev.

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

if dist==1
  % get the default job manager/scheduler
  sm = findResource();

  % create a job to run all subjects
  % use the current path, and override pathdef.m, jobStartup.m, etc.
  path_cell = regexp(path, ':', 'split');
  job_name = sprintf('apply_to_subj:%s', func2str(fcn_handle));
  job = createJob(sm, 'PathDependencies', path_cell, 'Name', job_name);
  
  % make a task for each subject
  for this_subj=subj
    createTask(job, fcn_handle, 1, {this_subj fcn_inputs{:}}, 'Name', this_subj.id);
  end

  % capture command window output for all tasks (helpful for debugging)
  alltasks = get(job, 'Tasks');
  set(alltasks, 'CaptureCommandWindowOutput', true);

  % submit the job and wait for it to finish
  tic
  submit(job);
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
  temp = getAllOutputArguments(job);
  if isempty(temp)
    return
  end

  % convert to structure
  for i=1:length(temp)
    if isempty(temp{i})
      continue
    end
    subj = setobj(subj, temp{i});
  end
elseif dist==2
  % use parfor
  tic
  new_subj = [];
  parfor i=1:length(subj)
    fprintf('%s\n', subj(i).id)
    new_subj = [new_subj fcn_handle(subj(i), fcn_inputs{:})];
  end
  subj = new_subj;
  fprintf('apply_to_subj: finished: %.2f seconds.\n', toc);
else
  % run the function on each element of the subject vector
  tic
  for i=1:length(subj)
    this_subj = subj(i);
    fprintf('%s\n', this_subj.id)
    % pass this subject as input to the function
    % and modify the subject vector
    subj = setobj(subj, fcn_handle(this_subj, fcn_inputs{:}));
  end
  fprintf('apply_to_subj: finished: %.2f seconds.\n', toc);
end
