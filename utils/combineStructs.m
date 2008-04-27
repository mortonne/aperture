function s = combineStructs(s1, s2)
%s = combineStructs(s1, s2)
% combines structs s1 and s2.  If a field exists for both s1 and
% s2, the value in s1 takes priority.

s = s1;

f2 = fieldnames(s2);
c2 = struct2cell(s2);
for i=1:length(f2)
  if ~isfield(s1, f2{i})
    s = setfield(s, f2{i}, c2{i});
  end
end

