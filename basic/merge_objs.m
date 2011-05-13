function objs = merge_objs(objs1, objs2)
%MERGE_OBJS  Merge two sets of objects.
%
%  Will recursively merge two sets of objects. That is, all
%  sub-structures of overlapping objects will be merged. Save your
%  inputs until after checking the merge; this is a complex operation
%  that may still have bugs.
%
%  Fields identified as objects will be recursively merged; fields that
%  are not objects will be merged with the first structure taking
%  precedence if there is a conflict, as in merge_structs.
%
%  objs = merge_objs(objs1, objs2)
%
%  EXAMPLE:
%   % merge two experiment objects
%   merged = merge_objs(exp1, exp2);

% add objects in set2 but not set1
names1 = get_obj_names(objs1);
names2 = get_obj_names(objs2);

[c, ind] = setdiff(names2, names1);

objs = [];
for i = 1:length(ind)
  objs = addobj(objs, objs2(ind(i)));
end

% get clones
[clones, i1, i2] = intersect(names1, names2);

clone_objs = [];
for i = 1:length(clones)
  clone1 = objs1(i1(i));
  clone2 = objs2(i2(i));

  % get two structs: one with objects, one with everything else
  [s_obj1, s_others1] = split_by_type(clone1);
  [s_obj2, s_others2] = split_by_type(clone2);
  
  % if obj field in one, but not other, use normal merging
  fn_obj1 = fieldnames(s_obj1);
  fn_obj2 = fieldnames(s_obj2);
  [c, ia, ib] = setxor(fn_obj1, fn_obj2);
  if ~isempty(ia)
    [s_obj1, s_others1] = transfer_fields(s_obj1, s_others1, fn_obj1(ia));
  end
  if ~isempty(ib)
    [s_obj2, s_others2] = transfer_fields(s_obj2, s_others2, fn_obj2(ib));
  end
  
  % for each clone, merge non-struct fields (1 takes precedence)
  others_merged = merge_structs(s_others1, s_others2);
  
  % for each struct field on both objs, if there is an
  % objname (on both objs), call recursively
  % each field should be in both
  fn_obj = fieldnames(s_obj1);
  obj_merged = struct;
  for j = 1:length(fn_obj)
    obj_merged.(fn_obj{j}) = merge_objs(s_obj1.(fn_obj{j}), ...
                                        s_obj2.(fn_obj{j}));
  end

  % switch to cell array so we can concatenate fields
  c = [struct2cell(others_merged); struct2cell(obj_merged)];
  fn_all = [fieldnames(others_merged); fieldnames(obj_merged)];
  
  % reorder fields to start with clone1 order
  fn1 = fieldnames(clone1);
  [all_true, old_loc] = ismember(fn1, fn_all);
  new_loc = find(~ismember(fn_all, fn1));
  order = [old_loc; new_loc];
  
  % merge and convert back to a struct
  merged = cell2struct(c(order,:), fn_all(order), 1);

  clone_objs = addobj(clone_objs, merged);
end

% fix order of clones
[all_true, old_loc] = ismember(names1, clones);
new_loc = find(~ismember(clones, names1));
ind = [old_loc; new_loc];
for i = 1:length(clone_objs)
  objs = addobj(objs, clone_objs(ind(i)));
end

function names = get_obj_names(objs)
%GET_OBJ_NAMES   Get names of a vector of objects.
%
%  names = get_obj_names(objs)

  names = cell(length(objs), 1);
  for i = 1:length(objs)
    names{i} = get_obj_name(objs(i));
  end

  
function [obj, others] = split_by_type(s)
%SPLIT_BY_TYPE   Split a structure into objects and non-objects.
%
%  [obj, others] = split_by_type(s)

  f = fieldnames(s);
  obj = struct;
  others = struct;
  for i = 1:length(f)
    if isstruct(s.(f{i}))
      % this is a struct, but is it an object or set of objects?
      s_nested = s.(f{i});
      names = get_obj_names(s_nested);
      if any(cellfun(@isempty, names))
        % not all structure elements have set names; treat as normal
        % field
        others.(f{i}) = s.(f{i});
      else
        % add this field to the objects structure
        obj.(f{i}) = s.(f{i});
      end
      
    else
      % add this field to the other fields stucture
      others.(f{i}) = s.(f{i});
    end
  end
  

function [s1_new, s2_new] = transfer_fields(s1, s2, fn)
%TRANSFER_FIELDS   Transfer fields from one struct to another.
%
%  [s1_new, s2_new] = transfer_fields(s1, s2, fn)

  s1_new = s1;
  s2_new = s2;

  for i = 1:length(fn)
    this_fn = fn{i}
    s2_new.(this_fn) = s1.(this_fn);
    s1_new = rmfield(s1_new, this_fn);
  end
  