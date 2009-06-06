function loc = get_obj_loc(obj)
%GET_OBJ_LOC   Get the location of an object's associated data.
%
%  loc = get_obj_loc(obj)
%
%  INPUTS:
%      obj:  an object.
%
%  OUTPUTS:
%      loc:  location of the object's data.  Can be:
%             'ws' - workspace; that is, the data is stored in
%                    obj.mat
%             'hd' - hard drive; the data is not in obj.mat, but
%                    is stored in a .mat file on disk

% input checks
if ~exist('obj','var') || ~isstruct(obj)
  error('You must pass an object.')
end

% get the location; if the matrix is attached to the object,
% that takes priority over saved files
if isfield(obj, 'mat') && ~isempty(obj.mat)
  loc = 'ws';
elseif isfield(obj, 'file') && ~isempty(obj.file)
  loc = 'hd';
else
  error('Object %s is not saved anywhere!', obj.name)
end
