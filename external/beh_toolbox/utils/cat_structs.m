function s = cat_structs(s1, s2)
%CAT_STRUCTS   Concatenate two vector structures.
%
%  s = cat_structs(s1, s2)
%
%  INPUTS:
%       s1:  a structure.
%
%       s2:  a structure to be concatenated onto s1.
%
%  OUTPUTS:
%        s:  concatenated structure.  Will have fieldnames from both
%            s1 and s2; if a field does not exist for one of the
%            original structures, the elements corresponding to that
%            structure will be [].

% input checks
if ~exist('s1', 'var')
  error('You must pass an s1.')
elseif ~exist('s2', 'var')
  error('You must pass an s2.')
end

if isempty(s1) && ~isempty(s2)
  s = s2;
  return
elseif isempty(s2)
  s = s1;
  return
end

if ~isvector(s1) || ~isvector(s2)
  error('Structures must be vectors.')
end

% structure lengths
n1 = length(s1);
n2 = length(s2);
n = n1 + n2;

% fieldnames
fn1 = fieldnames(s1);
fn2 = fieldnames(s2);

% get a cell array with values from both structs for shared fields
shared = intersect(fn1, fn2);
f_shared = cell(length(shared), n);
for i=1:length(shared)
  fn = shared{i};
  f1 = {s1.(fn)};
  f2 = {s2.(fn)};
  f_shared(i,:) = [f1 f2];
end

% get values from unique fields
[uniq,i1,i2] = setxor(fn1, fn2);
f_uniq = cell(length(uniq), n);
for i=1:length(i1)
  fn = fn1{i1(i)};
  j = find(strcmp(fn, uniq));
  f_uniq(j, 1:n1) = {s1.(fn)};
end
for i=1:length(i2)
  fn = fn2{i2(i)};
  j = find(strcmp(fn, uniq));
  f_uniq(j, n1 + 1:end) = {s2.(fn)};
end

% concatenate shared and unique fields
f = [f_shared; f_uniq];
fn = [shared; uniq];

% reorder fields to start with ones that were in s1, in their original order
[all_true, old_loc] = ismember(fn1, fn);
new_loc = find(~ismember(fn, fn1));
i = [old_loc; new_loc];

f = f(i,:);
fn = fn(i);

%[fn, i] = sort(fn);
%f = f(i,:);
s = cell2struct(f, fn, 1)';
