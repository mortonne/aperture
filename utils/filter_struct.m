function [s,i] = filter_struct(s, filt_fcn, filt_inputs)
%FILTER_STRUCT   Filter a structure using a custom function.
%
%  include = filter_struct(s, filt_fcn, filt_inputs)
%
%  INPUTS:
%            s:  a vector structure.
%
%     filt_fcn:  a handle to a function that takes one element of s as
%                its first argument and returns true or false, with true 
%                indicating that the element should be included in the 
%                filtered structure.
%
%  filt_inputs:  cell array of additional inputs to filt_fcn.
%
%  OUTPUTS:
%      include:  a logical array the same size as s.

if ~exist('filt_inputs','var')
  filt_inputs = {};
  elseif ~iscell(filt_inputs)
  error('filt_inputs must be a cell array.')
end
if ~exist('filt_fcn','var')
  error('You must specify a filter function.')
  elseif ~exist('s','var')
  error('You must pass a vector structure to filter.')
  elseif ~isstruct(s)
  error('s must be a structure.')
  elseif sum(size(s)>1)>1
  error('s must be one-dimensional.')
end

% initilize logical vector
include = false(size(s));

for i=1:length(s)
  % see if we want this element of the structure
  if filt_fcn(s(i), filt_inputs{:})
    include(i) = true;
  end
end

s = s(include);
i = include;
