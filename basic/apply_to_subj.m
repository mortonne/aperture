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
%   memory   - memory requested for each job (dist=1 only). ('1.5G')
%   max_jobs - if dist=1, this sets the maximum number of jobs to be
%              running at any given time. (Inf)
%
%  See also apply_to_subj_obj, apply_to_pat, apply_to_ev.

% input checks
if ~exist('subj', 'var')
  error('You must pass a subject structure.')
elseif ~exist('fcn_handle', 'var')
  error('You must pass a handle to a function.')
end
if ~exist('fcn_inputs', 'var')
  fcn_inputs = {};
end
if ~exist('dist', 'var')
  dist = 0;
end

% options
defaults.memory = '1.5G';
defaults.max_jobs = [];
params = propval(varargin, defaults);

if dist == 1
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
  
  % set limits on active at any time
  n_jobs = length(subj);
  n_running = 0;
  c = cell(1, 4);
  [c{:}] = findJob(sm);
  n_start = cellfun(@length, c);
  
  REFRESH = .5;
  next = 1;
  jobs = [];
  n_finished = 0;
  tic
  while n_finished < n_jobs
    pause(REFRESH)

    % update counts
    [c{:}] = findJob(sm);
    
    % get total number of tasks for each type
    totals = zeros(1, 4);
    for i = 1:length(c)
      for j = n_start(i) + 1:length(c{i})
        totals(i) = totals(i) + length(c{i}(j).tasks);
      end
    end
    
    % for running, some tasks may be finished
    counts = zeros(1, 4);
    counts([1 2 4]) = totals([1 2 4]);
    for j = n_start(3) + 1:length(c{3})
      [p, r, f] = findTask(c{3}(j));
      counts(3) = counts(3) + length(r);
      counts(4) = counts(4) + length(f);
    end
    
    n_running = sum(counts(1:3));
    n_finished = counts(4);
    n_left = n_jobs - (next - 1);
    
    % submit more jobs
    if n_left > 0 && n_running < params.max_jobs
      n_needed = min([n_left params.max_jobs - n_running]);
      job_name = sprintf('apply_to_subj:%s', func2str(fcn_handle));
      job = createJob(sm, 'FileDependencies', {job_startup_file}, ...
                      'Name', job_name);
      job.PathDependencies = path_cell;
      
      for i = 1:n_needed
        this_subj = subj(next);
        name = get_obj_name(this_subj);
        
        % make a task
        createTask(job, fcn_handle, 1, ...
                   {this_subj fcn_inputs{:}}, 'Name', name);
        next = next + 1;
      end
      
      % capture command window output for all tasks
      % (helpful for debugging)
      alltasks = get(job, 'Tasks');
      set(alltasks, 'CaptureCommandWindowOutput', true);
      submit(job);
      
      jobs = [jobs job];
    end
  end
  fprintf('apply_to_subj: jobs finished: %.2f seconds.\n', toc);
  
  % report any errors
  fprintf('loading updated subjects...')
  for i = 1:length(jobs)
    n_tasks = length(jobs(i).tasks);
    for j = 1:n_tasks
      task = jobs(i).tasks(j);
      if ~isempty(task.ErrorMessage)
        warning('eeg_ana:apply_to_subj:SubjError', ...
                '%s threw an error for subject %s:\n  %s', ...
                func2str(fcn_handle), task.Name, getReport(task.Error))
        continue
      end
    end
    
    temp = getAllOutputArguments(jobs(i));
    if isempty(temp)
      continue
    end
    for j = 1:n_tasks
      subj = addobj(subj, temp{j});
    end
  end
  fprintf('done.\n')
    
elseif dist == 2
  % use parfor
  tic
  new_subj = [];
  parfor i = 1:length(subj)
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
  for i = 1:length(subj)
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
