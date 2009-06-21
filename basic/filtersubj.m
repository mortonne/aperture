function [subj,match] = filtersubj(subj,numbers,include)
%FILTERSUBJ   Filter a subject structure using numbers instead of strings.
%
%  [subj, match] = filtersubj(subj, numbers, include)
%
%  INPUTS:
%     subj:  a subject structure. Must be a vector structure with an "id"
%            field.
%
%  numbers:  array of numbers corresponding to the numeric part of a set
%            of subject ids.
%
%  include:  boolean indicating whether to include (true) or exclude (false)
%            the subjects corresponding to the numbers array.
%
%  OUTPUTS:
%     subj:  a filtered subject structure.
%
%    match:  a boolean array of the same length as the unfiltered subject
%            structure; true for subjects that were included.
%
%  EXAMPLE:
%   % subject ids are: 'LTP001', 'LTP002', 'LTP003'
%   % get subjects LTP002 and LTP003
%   subj = filtersubj(subj,2:3,1)
%
%   % get subject LTP001
%   subj = filtersubj(subj,2:3,0)

% input checks
if ~exist('subj','var') || ~isstruct(subj)
  error('You must pass a subject structure.')
end
if ~exist('numbers','var')
  match = true(1,length(subj));
  return
end
if ~exist('include','var')
  include = 1;
end

if ~iscell(numbers)
  % convert the subject id's to numbers
  subjs = {subj.id};
  usubjs = unique(subjs);
  for s=1:length(usubjs)
    id = usubjs{s};
    num(s) = str2num(id(isstrprop(id,'digit')));
  end
  
  else
  num = {subj.id};
end

% filter subjects
if ~isempty(numbers)
  match = ismember(num,numbers);
  if ~include
    match = ~match;
  end
  subj = subj(match);
end
