function exp = load_job(exp, job, method, obj_type)
%LOAD_JOB   Load a completed distributed job and merge into an experiment object.
%
%  exp = load_job(exp, job, method, obj_type)
%
%  INPUTS:
%       exp:  an experiment object.
%
%       job:  job object for a job submitted using apply_to_subj,
%             apply_to_pat, or apply_to_ev. May also be a vector of
%             jobs, whose outputs will be merged into exp in order.
%
%    method:  method for dealing with conflicts if the loaded objects
%             have the same name and type as existing objects:
%              'merge'   - merge with existing objects (and subobjects)
%                          using the magic of merge_objs. (default)
%              'replace' - replace existing objects.
%
%  obj_type:  type of object to be loaded. If not specified, this will
%             be determined automatically. If an object fails to load,
%             try setting this option. May be:
%              'subj' - job was submitted with apply_to_subj
%              'pat'  - for apply_to_pat
%              'ev'   - for apply_to_ev
%
%  OUTPUTS:
%      exp:  experiment object that has been merged with the loaded job
%            output.
%
%  EXAMPLES:
%   >> job = apply_to_subj(exp.subj, @my_analysis_func, {}, 1, 'async', 1);
%   >> % (wait for job to finish...)
%   >> exp = load_job(exp, job);
%
%  NOTES:
%   Involves some potentially buggy fanciness. Backup your experiment
%   object before running.

if ~exist('method', 'var')
  method = 'merge';
end
if ~exist('obj_type', 'var')
  obj_type = '';
end

for i = 1:length(job)
  if ~strcmp(job(i).state, 'finished')
    fprintf('Job %d not finished yet. Skipping...\n', job(i).ID)
    continue
  end
  
  outputs = getAllOutputArguments(job(i));
  for j = 1:length(outputs)
    if isempty(outputs{j})
      fprintf('Output from job "%s" for %s is empty.\n', ...
              job(i).name, job(i).tasks(j).name)
      continue
    end

    %if strcmp(job(i).Name, 'apply_to_subj:apply_to_obj')
    issubobj = strcmp(get_obj_type(outputs{j}), 'subj') && ...
               isfield(outputs{j}, 'obj') && ...
               isfield(outputs{j}, 'obj_name');
    if (~isempty(obj_type) && strcmp(obj_type, 'subj')) || ~issubobj
      obj = outputs{j};
    elseif (~isempty(obj_type) && ismember(obj_type, {'pat' 'ev'})) || issubobj
      % grab the object from the fake subject
      obj = outputs{j}.obj;
      if length(obj) == 2
        [o,j] = getobj(outputs{j}, 'obj', outputs{j}.obj_name);
        j = setdiff(1:2, j);
        obj = obj(j);
      end
    end

    obj_type = get_obj_type(obj);
    obj_name = get_obj_name(obj);
    if strcmp(obj_type, 'subj')
      switch method
       case 'merge'
        % merge with the old subject
        if exist_obj(exp, 'subj', obj_name)
          old_subj = getobj(exp, 'subj', obj_name);
          merged_subj = merge_objs(old_subj, obj);
          exp = setobj(exp, 'subj', merged_subj);
        else
          exp = setobj(exp, 'subj', obj);
        end
       case 'replace'
        % replace the old subject
        exp = setobj(exp, 'subj', obj);
      end
      
    else
      % get the parent so we know where to put it
      obj_parent = get_obj_parent(obj);
      if isempty(obj_parent)
        error('Cannot determine object parent.')
      end
      
      % make sure the parent is a subject
      obj_subj = getobj(exp, 'subj', obj_parent);
      if ~strcmp(get_obj_type(obj_subj), 'subj')
        error('Object may not be nested more than one level.')
      end
      
      switch method
       case 'merge'
        if exist_obj(obj_subj, obj_type, obj_name)
          % merge with the old object
          old_obj = getobj(obj_subj, obj_type, obj_name);
          merged_obj = merge_objs(old_obj, obj);
          exp = setobj(exp, 'subj', obj_parent, obj_type, merged_obj);
        else
          exp = setobj(exp, 'subj', obj_parent, obj_type, obj);
        end
          
       case 'replace'
        % replace the old object
        exp = setobj(exp, 'subj', obj_parent, obj_type, obj);
      end
    end
    
  end
end

