function s_out = apply_to_obj(s,obj_type,obj_name,fcn_handle,fcn_inputs)
%APPLY_TO_OBJ   Apply a function to a child object, then return the parent.
%
%  s_out = apply_to_obj(s, obj_type, obj_name, fcn_handle, fcn_inputs)
%
%  In many cases you need to run a function on a child object, then
%  immediately update the parent object with the modified child.  For
%  example, you might want to modify a pat object, then update its
%  parent subj object.
%
%  INPUTS:
%           s:  a structure
%
%    obj_type:  the "type" of object that you want to modify.  Must be a
%               subfield of s.
%
%    obj_name:  the string identifier for the object that you want to
%               modify.
%
%  fcn_handle:  handle to a function to input the object.  The first
%               input should be the object, and the first output should
%               be an object of the same type.
%
%  fcn_inputs:  a cell array of additional inputs to fcn_handle (the
%               object is the first input).
%
%  OUTPUTS:
%       s_out:  same a s, but the object specified by obj_type and
%               obj_name is modified.
%
%  EXAMPLES:
%   % we want to modify one subject's pattern named 'voltage' using the
%   % function called "modify_pattern"
%   subj = apply_to_obj(subj,'pat','voltage',@modify_pattern,{input1,input2})
%
%  See also applytosubj, apply_to_pat.

% input checks  
if ~exist('s','var')
  error('You must pass an object whose child object you want to modify.')
elseif ~exist('obj_type','var')
  error('You must specify an object type.')
elseif ~exist('obj_name','var')
  error('You must give the name of an object.')
elseif ~exist('fcn_handle','var')
  error('You must specify a function to run.')
end
if ~exist('fcn_inputs','var')
  fcn_inputs = {};
end

% if we error out, return the unmodified structure
s_out = s;

% get the object we want to modify
try
  obj = getobj(s, obj_type, obj_name);
catch
  % couldn't find it
  warning('%s object %s not found.', obj_type, obj_name)
  return
end

% set the source field of the object
obj.source = get_obj_name(s);

% run the function
obj = fcn_handle(obj, fcn_inputs{:});

% update the structure with the modified object
s_out = setobj(s, obj_type, obj);
