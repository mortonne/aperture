function subj = rm_obj_field(subj, obj_type, field)
%RM_OBJ_FIELD   Remove a field from an object type for all subjects.
%
%  subj = rm_obj_field(subj, obj_type, field)
%
%  INPUTS:
%      subj:  vector of subject objects.
%
%  obj_type:  string indicating the type of object to modify.
%
%     field:  string name of the field to remove from all objects of
%             type obj_type.
%
%  OUTPUTS:
%      subj:  modified vector of subject objects.

% input checks
if ~exist('subj', 'var') || ~isstruct(subj)
  error('You must pass a vector of subject objects.')
elseif ~exist('obj_type', 'var') || ~ischar(obj_type)
  error('You must indicate the type of object to modify.')
elseif ~exist('field', 'var') || ~ischar(field)
  error('You must specify which field to remove.')
end

new_subj = cell(1, length(subj));
for i=1:length(subj)
  objs = subj(i).(obj_type);
  
  % get a cell array of modified objects
  new_objs = cell(1, length(objs));
  for j=1:length(objs)
    new_objs{j} = rmfield(objs(j), field);
  end
  
  % add the new objects to the new subject
  new_subj{i} = subj(i);
  new_subj{i}.(obj_type) = [new_objs{:}];
end

subj = [new_subj{:}];
