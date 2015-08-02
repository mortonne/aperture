function s = update_struct(old, new, id_fields)
%UPDATE_STRUCT   Update elements of a structure with new data.
%
%  Find elements of old that match elements of new, and update
%  them. Matches are determined by identifier fields of the two
%  structures; elements are considered to match if their values on
%  each of the identifier fields are equal.
%
%  Currently, updated elements of old are completely replaced by
%  elements of new; in the future, may add support for merging
%  individual fields.
%
%  s = update_struct(old, new, id_fields)
%
%  INPUTS:
%        old:  old structure.
%
%        new:  structure with some new data.
%
%  id_fields:  string or cell array of strings specifying the field(s)
%              whose combination determines uniqueness of elements of
%              the structures.
%
%  OUTPUTS:
%          s:  updated structure.
%
%  EXAMPLE:
%   >> old = struct('shared', {1 2}, 'old_only', {1 2}, 'id', {'x' 'y'});
%   >> new = struct('shared', {3 5}, 'new_only', {9 10}, 'id', {'y' 'z'});
%   >> s = update_struct(old, new, 'id');
%   >> disp(s(1))
%         shared: 1
%       old_only: 1
%             id: 'x'
%       new_only: []
%   >> disp(s(2))
%         shared: 3
%       old_only: []
%             id: 'y'
%       new_only: 9

if ~iscell(id_fields)
  id_fields = {id_fields};
end

f_old = fieldnames(old);
f_new = fieldnames(new);

% make sure both structures have all id fields
if ~all(ismember(id_fields, f_old))
  error('old does not have all identifier fields.')
elseif ~all(ismember(id_fields, f_new))
  error('old does not have all identifier fields.')
end

% make a unique index across both structs and all ID fields
id_cell = cell(1,length(id_fields));
for i=1:length(id_fields)
  f = id_fields{i};
  
  % store ids from both in a cell array
  id_cell{i} = {old.(f) new.(f)};
  
  % if numeric data, make a vector
  if isnumeric(id_cell{i}{1})
    id_cell{i} = cell2mat(id_cell{i});
  end
end
index = make_index(id_cell{:});

% separate the indices
i_old = index(1:length(old));
i_new = index(length(old) + 1:end);
if ~isunique(i_old)
  error('The given ID fields are not unique for the old events.')
elseif ~isunique(i_new)
  error('The given ID fields are not unique for the new events.')
end

% find the indices to be replaced
outdated = ismember(i_old, i_new);
updates = ismember(i_new, i_old);

% create a new structure with the outdated elements replaced with
% their new versions
s = cat_structs(old(~outdated), new(updates));

function tf = isunique(x)
  if length(unique(x)) < length(x)
    tf = false;
  else
    tf = true;
  end
%endfunction
