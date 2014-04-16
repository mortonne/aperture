function exp = load_job(exp, job, varargin)
%LOAD_JOB   Load a completed distributed job and merge into an experiment object.
%
%  exp = load_job(exp, job, ...)
%
%  INPUTS:
%       exp:  an experiment object.
%
%       job:  job object for a job submitted using apply_to_subj,
%             apply_to_pat, or apply_to_ev. May also be a vector of
%             jobs, whose outputs will be merged into exp in order.
%
%  OUTPUTS:
%      exp:  experiment object that has been merged with the loaded job
%            output.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   method   - method for dealing with conflicts if the loaded objects
%              have the same name and type as existing objects:
%               'merge'   - merge with existing objects (and subobjects)
%                           using the magic of merge_objs. (default)
%               'replace' - replace existing objects.
%   obj_type - type of object to be loaded. If not specified, this will
%              be determined automatically. If an object fails to load,
%              try setting this option. May be:
%               'subj' - job was submitted with apply_to_subj
%               'pat'  - for apply_to_pat
%               'ev'   - for apply_to_ev
%   obj_path - path to the sub-object to merge/replace, in obj_type,
%              obj_name pairs (e.g. {'pat' 'my_pat_name'}). ({})
%
%  EXAMPLES:
%   >> job = apply_to_subj(exp.subj, @my_analysis_func, {}, 1, 'async', 1);
%   >> % (wait for job to finish...)
%   >> exp = load_job(exp, job);
%
%  NOTES:
%   Involves some potentially buggy fanciness. Backup your experiment
%   object before running.

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

% options
defaults.method = 'merge';
defaults.obj_type = '';
defaults.obj_path = {};
params = propval(varargin, defaults);

for i = 1:length(job)
  if ~strcmp(job(i).State, 'finished')
    fprintf('Job %d not finished yet. Skipping...\n', job(i).ID)
    continue
  end
  
  outputs = fetchOutputs(job(i));
  for j = 1:length(outputs)
    if isempty(outputs{j})
      fprintf('Output from job "%s" for %s is empty.\n', ...
              job(i).Name, job(i).Tasks(j).Name)
      continue
    end

    %if strcmp(job(i).Name, 'apply_to_subj:apply_to_obj')
    issubobj = strcmp(get_obj_type(outputs{j}), 'subj') && ...
               isfield(outputs{j}, 'obj') && ...
               isfield(outputs{j}, 'obj_name') && ...
               ~isfield(outputs{j}, 'sess');
    if (~isempty(params.obj_type) && ...
        strcmp(params.obj_type, 'subj')) || ~issubobj
      obj = outputs{j};
    elseif (~isempty(params.obj_type) && ...
            ismember(params.obj_type, {'pat' 'ev'})) || issubobj
      % grab the object from the fake subject
      obj = outputs{j}.obj;
      if length(obj) == 2
        [o, ind] = getobj(outputs{j}, 'obj', outputs{j}.obj_name);
        ind = setdiff(1:2, ind);
        obj = obj(ind);
      end
    end

    % once we've loaded the obj, get a sub-object if requested
    if ~isempty(params.obj_path)
      obj = getobj(obj, params.obj_path{:});
    end
    
    obj_type = get_obj_type(obj);
    obj_name = get_obj_name(obj);
    if strcmp(obj_type, 'subj')
      switch params.method
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
      
      switch params.method
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

