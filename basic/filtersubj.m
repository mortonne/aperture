function [subj,match] = filtersubj(subj,numbers,include)
%FILTERSUBJ   Filter a subj structure using numbers instead of strings.
%   SUBJ = FILTERSUBJ(SUBJ,NUMBERS,INCLUDE) filters the
%   structure SUBJ. NUMBERS is an array of integers indicating
%   which subjects to match, and INCLUDE is a boolean indicating
%   whether to include (1) or exclude (0) matching subjects.
%
%   Numbers are extracted from the "id" field of each subject.
%
%   Example
%    If subject ids are: 'LTP001', 'LTP002', 'LTP003'
%    subj = filtersubj(subj,2:3,1) gets subjects LTP002 and LTP003, while
%    subj = filtersubj(subj,2:3,0) gets subject LTP001.
%

% convert the subject id's to numbers
subjs = {subj.id};
usubjs = unique(subjs);
for s=1:length(usubjs)
  id = usubjs{s};
  num(s) = str2num(id(isstrprop(id,'digit')));
end

% filter subjects
match = ismember(num,numbers);
if include
  subj = subj(match);
  else
  subj = subj(~match);
end
