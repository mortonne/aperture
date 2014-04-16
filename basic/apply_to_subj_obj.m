function subj = apply_to_subj_obj(subj, obj_path, fcn_handle, ...
                                  fcn_inputs, dist, varargin)
%APPLY_TO_SUBJ_OBJ   Apply a function to an object for all subjects.
%
%  subj = apply_to_subj_obj(subj, obj_path, fcn_handle, fcn_inputs, dist, ...)
%  
%  INPUTS:
%        subj:  a [1 X N subjects] structure representing each subject
%               in an experiment.
%
%    obj_path:  cell array of obj_type, obj_name pairs specifying the
%               location (within each subject) of the object to modify.
%
%  fcn_handle:  a handle for a function of the form
%                obj = fcn_handle(obj, ...)
%               If the function modifies obj.name, a new object with
%               that name will be added.  Otherwise, the old object will
%               be overwritten.
%
%  fcn_inputs:  a cell array of additional inputs (after obj) to
%               fcn_handle.
%
%        dist:  distributed evaluation; see apply_to_subj for possible
%               values.
%
%  OUTPUTS:
%        subj:  a modified subjects vector.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   memory - memory requested for each job (dist=1 only). ('1G')
%   max_jobs - if dist=1, this sets the maximum number of jobs to be
%              running at any given time. (Inf)
%
%  See also apply_to_subj, apply_to_obj.

% input checks
if ~exist('subj','var')
  error('You must pass a subjects vector.')
elseif ~exist('obj_path', 'var')
  error('You give the path to an object.')
elseif ~exist('fcn_handle','var')
  error('You must pass a handle to a function.')
end
if ~exist('fcn_inputs','var')
  fcn_inputs = {};
end
if ~exist('dist','var')
  dist = false;
end

if dist
  % create dummy subjects, so there is less to send to each worker.
  % this is necessary because just sending in a vector of objects
  % causes problems when fcn_handle changes the name of the returned
  % object.
  obj_name = obj_path{end};
  objs = getobjallsubj(subj, obj_path);
  ids = cell(1, length(subj));
  for i = 1:length(subj)
    ids{i} = get_obj_name(subj(i));
  end
  temp_subj = struct('id', ids, 'obj', num2cell(objs), ...
                     'obj_name', obj_name);
  
  % run the function on each subject's object
  temp_subj = apply_to_subj(temp_subj, @apply_to_obj, ...
                            {{'obj', obj_name}, fcn_handle, fcn_inputs}, ...
                            dist, varargin{:});

  % check if we're running asynchronously
  if ismember(class(temp_subj), ...
              {'distcomp.simplejob' 'parallel.job.CJSIndependentJob'})
    subj = temp_subj;
    return
  end
  
  % add the modified objects to the subjects
  for i = 1:length(subj)
    obj = temp_subj(i).obj;
    
    % if there are two objects, get the new one
    if length(obj) == 2
      [o,j] = getobj(temp_subj(i), 'obj', obj_name);
      j = setdiff(1:2, j);
      obj = obj(j);
    end
    
    % add the modified/new object
    subj(i) = setobj(subj(i), obj_path{1:end-1}, obj);
  end
  
else
  % not copying anything to workers, so regular apply_to_subj works fine
  subj = apply_to_subj(subj, @apply_to_obj, ...
                      {obj_path, fcn_handle, fcn_inputs}, dist, varargin{:});
end

