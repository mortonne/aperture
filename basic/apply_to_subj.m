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
%   async    - if true, will not wait for jobs to finish. Vector of job
%              objects will be returned instead of subj (dist=1 only).
%              (false)
%   memory   - memory requested for each job (dist=1 only). ('1.7G')
%   walltime - wall time to for each job ('hh:mm:ss').  This value
%              should be at least 5 minutes, or '00:05:00' (dist=1
%              only, Torque).  ('00:15:00')
%   arch     - specify requested architecture for jobs to run on.
%              To run on any nodes, leave empty (dist=1 only). ('')
%   max_jobs - if dist=1, this sets the maximum number of jobs to be
%              running at any given time. (Inf)
%   debug    - if true, will stop execution if any subject throws an
%              error. If false, error information will be printed, but
%              all other subjects will continue running. (false)
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
defaults.async = false;
defaults.memory = '2G';
defaults.walltime = '00:30:00'; % Torque
defaults.arch = '';             % Torque 
defaults.max_jobs = Inf;
defaults.debug = true;
defaults.out_type = 'obj';
defaults.dim = 1;
params = propval(varargin, defaults);

if params.debug
  dbstop if error
end

if dist == 1
  sm = getScheduler();
  sm = setQsub(sm, params);
  
  % set limits on active at any time
  n_jobs = length(subj);
  REFRESH = 2;
  next = 1;
  jobs = [];
  n_running = 0;
  n_submitted = 0;
  if strcmp(params.out_type, 'obj')
    n_out = 1;
  else
    n_out = nargout(fcn_handle);
  end
  tic
  first = false;
  while n_submitted < n_jobs
    if ~first
      pause(REFRESH)
    else
      first = false;
    end

    % update counts
    counts = get_task_states(jobs);
    n_running = sum(counts(1:3));
    n_left = n_jobs - n_submitted;
    
    % submit more jobs
    if n_left > 0 && n_running < params.max_jobs
      n_needed = min([n_left params.max_jobs - n_running]);
      job_name = get_job_name(fcn_handle, subj(next), fcn_inputs);
      job = createJob(sm, 'Name', job_name);
      
      for i = 1:n_needed
        this_subj = subj(next);
        name = get_obj_name(this_subj);
        
        % make a task
        createTask(job, fcn_handle, n_out, ...
                   {this_subj fcn_inputs{:}}, 'Name', name);
        next = next + 1;
        n_submitted = n_submitted + 1;
      end
      
      % capture command window output for all tasks
      alltasks = get(job, 'Tasks');
      set(alltasks, 'CaptureDiary', true);
      submit(job);
      fprintf('job %d submitted with %d tasks.\n', job.ID, n_needed);
      
      jobs = [jobs job];
    end
  end
  
  if params.async
    subj = jobs;
    return
  end

  % wait for remaining tasks to finish
  wait_for_jobs(jobs)
  
  fprintf('apply_to_subj: jobs finished: %.2f seconds.\n', toc);
  
  % report any errors
  x = [];
  fprintf('loading updated subjects...')
  for i = 1:length(jobs)
    n_tasks = length(jobs(i).Tasks);
    for j = 1:n_tasks
      task = jobs(i).Tasks(j);
      if ~isempty(task.ErrorMessage)
        warning('eeg_ana:apply_to_subj:SubjError', ...
                '%s threw an error for subject %s:\n  %s', ...
                func2str(fcn_handle), task.Name, getReport(task.Error))
        continue
      end
    end
    
    temp = fetch_outputs_robust(jobs(i));
    if isempty(temp)
      continue
    end
    switch params.out_type
      case 'obj'
        % output is some object
        for j = 1:n_tasks
          subj = addobj(subj, temp{j});
        end
      case 'array'
        % output can use standard concatenation
        x = cat(params.dim, x, temp{:});
      case 'cell'
        if isempty(x)
          x = temp;
        else
          x = [x temp];
        end
      otherwise
        error('Invalid out_type.')
    end
  end
  if ~isempty(x)
    subj = x;
  end
  fprintf('done.\n')
    
elseif dist == 2
  % use parfor
  if ~strcmp(params.out_type, 'obj')
    error('Only object outputs are supported for dist 2')
  end
  
  tic
  new_subj = [];
  parfor i = 1:length(subj)
    if length(subj) > 1
      fprintf('%s\n', get_obj_name(subj(i)))
    end
    
    % apply to this subject
    try
      % add subject output by function
      new_subj = [new_subj fcn_handle(subj(i), fcn_inputs{:})];
    catch err
      fprintf('error thrown for %s:\n', subj(i).id)
      getReport(err)
      % error; just add the old subject
      new_subj = [new_subj subj(i)];
    end
  end
  subj = new_subj;
  if length(subj) > 1
    fprintf('apply_to_subj: finished: %.2f seconds.\n', toc);
  end
  
else
  % run the function on each element of the subject vector
  tic
  x = [];
  for i = 1:length(subj)
    this_subj = subj(i);
    if length(subj) > 1
      fprintf('%s\n', get_obj_name(this_subj))
    end
    % pass this subject as input to the function
    % and modify the subject vector
    if params.debug
      subj_out = fcn_handle(this_subj, fcn_inputs{:});
    else
      try
        subj_out = fcn_handle(this_subj, fcn_inputs{:});
      catch err
        fprintf('error thrown for %s:\n', this_subj.id)
        getReport(err)
        subj_out = this_subj;
        %subj_out = [];
      end
    end
    if strcmp(params.out_type, 'obj')
      subj = addobj(subj, subj_out);
    else
      x = cat(params.dim, x, subj_out);
    end
  end
  
  if strcmp(params.out_type, 'array')
    subj = x;
  end
  if length(subj) > 1
    fprintf('apply_to_subj: finished: %.2f seconds.\n', toc);
  end
end


function job_name = get_job_name(f, subj, inputs)

  f_name = func2str(f);
  issubobj = isfield(subj, 'obj') && ...
      isfield(subj, 'obj_name') && ...
      ~isfield(subj, 'sess') && ...
      strcmp(f_name, 'apply_to_obj');
  if issubobj
    obj_type = get_obj_type(subj.obj);
    sub_f_name = func2str(inputs{2});
    job_name = sprintf('apply_to_%s:%s', obj_type, sub_f_name);
  else
    job_name = sprintf('apply_to_subj:%s', f_name);
  end
  