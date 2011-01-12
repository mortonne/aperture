function s = combineStructs(s1, s2)
%COMBINESTRUCTS   Combine the fields of two structures.
%   S = COMBINESTRUCTS(S1,S2) combines structs S1 and S2.  If a
%   field exists for both S1 and S2, the value in S1 takes
%   priority.
%

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

if isempty(s2)
  s2 = struct;
end

s = s1;

f1 = fieldnames(s1);
f2 = fieldnames(s2);

[c,i1,i2] = setxor(f1,f2);

c2 = struct2cell(s2);

for i=i2(:)'
  [s.(f2{i})] = c2{i,:};
end
