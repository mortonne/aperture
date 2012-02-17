function exp = load_exp_job(exp, job, obj_path)
%LOAD_EXP_JOB   Load a job that added an object to an experiment.
%
%  exp = load_exp_job(exp, job, obj_path)
%
%  INPUTS:
%       exp:  experiment object.
%
%       job:  job (or vector of jobs) created by running apply_to_exp with
%             async=true.
%
%  obj_path:  cell array of strings giving the path to an object that
%             was modified by the job. If multiple jobs, must pass a
%             cell array, where obj_path{i} contains the path for job i.
%
%  OUTPUTS:
%      exp:  experiment object with the new object from the experiment
%            output by the job.
%
%  See also load_job, apply_to_exp.

if iscellstr(obj_path)
  obj_path = {obj_path};
end

for i = 1:length(job)
  temp = getAllOutputArguments(job(i));
  %if ~exist_obj(temp{1}, obj_path{:})
  %  fprintf('Warning: object missing for %s\n', temp{1}
  
  this_obj_path = obj_path{i};
  if length(this_obj_path) > 2
    this_obj_path = this_obj_path(1:2);
  end
  
  obj = getobj(temp{1}, this_obj_path{:});
  exp = setobj(exp, this_obj_path{1:end-1}, obj);
end

