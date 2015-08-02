function s = union_structs(s1, s2, id_fields)
%UNION_STRUCT   Structure union.
%
%  Return the union of two array structures. Matches are determined by
%  identifier fields of the two structures; elements are considered to
%  match if their values on each of the identifier fields are equal.
%
%  For matching elements, the first structure takes precedence.
%
%  s = union_structs(s1, s2, id_fields)
%
%  INPUTS:
%         s1:  a structure. Will take precedence if there are
%              overlapping elements.
%
%         s2:  structure with some new data.
%
%  id_fields:  string or cell array of strings specifying the field(s)
%              whose combination determines uniqueness of elements of
%              the structures.
%
%  OUTPUTS:
%          s:  updated structure.
%
%  EXAMPLE:
%   >> s1 = struct('shared', {1 2}, 's1_only', {1 2}, 'id', {'x' 'y'});
%   >> s2 = struct('shared', {3 5}, 's2_only', {9 10}, 'id', {'y' 'z'});
%   >> s = union_structs(s1, s2, 'id');
%   >> disp(s(1))
%         shared: 1
%        s1_only: 1
%             id: 'x'
%        s2_only: []
%   >> disp(s(2))
%         shared: 2
%        s1_only: 2
%             id: 'y'
%        s2_only: []
%   >> disp(s(3))
%         shared: 5
%        s1_only: []
%             id: 'z'
%        s2_only: 10
%
%  See also update_struct.

if length(s1) == 0
  s = s2;
  return
end
if length(s2) == 0
  s = s1;
  return
end

if ~iscell(id_fields)
  id_fields = {id_fields};
end

f_s1 = fieldnames(s1);
f_s2 = fieldnames(s2);

% make sure both structures have all id fields
if ~all(ismember(id_fields, f_s1))
  error('s1 does not have all identifier fields.')
elseif ~all(ismember(id_fields, f_s2))
  error('s2 does not have all identifier fields.')
end

% make a unique index across both structs and all ID fields
id_cell = cell(1,length(id_fields));
for i=1:length(id_fields)
  f = id_fields{i};
  
  % store ids from both in a cell array
  id_cell{i} = {s1.(f) s2.(f)};
  
  % if numeric data, make a vector
  if isnumeric(id_cell{i}{1})
    id_cell{i} = cell2mat(id_cell{i});
  end
end
index = make_index(id_cell{:});

% separate the indices
i_s1 = index(1:length(s1));
i_s2 = index(length(s1) + 1:end);
if ~isunique(i_s1)
  error('The given ID fields are not unique for the s1 events.')
elseif ~isunique(i_s2)
  error('The given ID fields are not unique for the s2 events.')
end

% find elements of s2 that do not overlap with s1
to_add = ~ismember(i_s2, i_s1);

% create a new structure
s = cat_structs(s1, s2(to_add));

function tf = isunique(x)
  if length(unique(x)) < length(x)
    tf = false;
  else
    tf = true;
  end
%endfunction
