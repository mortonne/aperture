function s = combineStructs(s1, s2)
%
%COMBINESTRUCTS   Combine the fields of two structures.
%   S = COMBINESTRUCTS(S1,S2) combines structs S1 and S2.  If a
%   field exists for both S1 and S2, the value in S1 takes
%   priority.
%

if isempty(s2)
  s2 = struct;
end

s = s1;

f2 = fieldnames(s2);
c2 = struct2cell(s2);
for i=1:length(f2)
  if ~isfield(s1, f2{i})
		s.(f2{i}) = c2{i};
  end
end
