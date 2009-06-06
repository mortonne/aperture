function obj = remove_mat(obj)
%REMOVE_MAT   Remove the matrix for an object.
%
%  obj = remove_mat(obj)
%
%  INPUTS:
%      obj:  an object.
%
%  OUTPUTS:
%      obj:  the modified object.

% input checks
if ~exist('obj','var') || ~isstruct(obj)
  error('You must pass an object.')
elseif ~isfield(obj,'mat')
  error('object does not have a "mat" field.')
end

if isfield(obj, 'len')
  len = obj.len;
end

% set to an empty array
obj = set_mat(obj, []);

if isfield(obj, 'len')
  obj.len = len;
end
