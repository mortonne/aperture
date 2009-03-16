function subj = apply_to_subj(subj,fcn_handle,fcn_inputs,dist)
%APPLYTOSUBJ   Apply a function to all subjects.
%
%  subj = apply_to_subj_test(subj, fcn_handle, fcn_inputs)
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
%        dist:  if true, each subject will be evaluated with
%               a different distributed task.
%
%  OUTPUTS:
%        subj:  a subject vector.
%
%  See also apply_to_obj, apply_to_pat, distcomp/apply_to_subj.

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
  dist = true;
end

if dist
  % get the default job manager/scheduler
  sm = findResource();

  % create a job to run all subjects
  job = createJob(sm);
  for this_subj=subj
    % make a task to run this subject
    createTask(job, fcn_handle, 1, {this_subj fcn_inputs{:}});
  end

  % capture command window output for all tasks
  alltasks = get(job, 'Tasks');
  set(alltasks, 'CaptureCommandWindowOutput', true);

  % submit the job and wait for it to finish
  tic
  submit(job);
  wait(job);
  fprintf('apply_to_subj: job finished: %d seconds.\n', toc);

  % get a cell array of output arguments from each task
  temp = getAllOutputArguments(job);

  if isempty(temp)
    error('No output from %s.', func2str(fcn_handle))
  end

  % convert to structure
  for i=1:length(temp)
    subj = setobj(subj, temp{i});
  end
  
  else
  % run the function on each element of the subject vector
  for this_subj=subj
    fprintf('%s\n', this_subj.id)

    % pass this subject as input to the function
    % and modify the subject vector
    subj = setobj(subj, fcn_handle(this_subj, fcn_inputs{:}));
  end
end
