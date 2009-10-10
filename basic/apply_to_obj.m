function s_out = apply_to_obj(s, varargin)
%APPLY_TO_OBJ   Apply a function to a child object, then return the parent.
%
%  s_out = apply_to_obj(s, obj_path, fcn_handle, fcn_inputs)
%
%  In many cases you need to run a function on a child object, then
%  immediately update the parent object with the modified child.  For
%  example, you might want to modify a pat object, then update its
%  parent subj object.
%
%  If the function changes the name field of the object, a new object
%  will be added to s.  Otherwise, the old object will be overwritten.
%
%  INPUTS:
%           s:  a structure
%
%    obj_path:  cell array of obj_type, obj_name pairs specifying the
%               location of the object to modify.
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
%   obj_path = {'pat', 'voltage'};
%   f = @modify_pattern;
%   f_inputs = {input1, input2};
%   subj = apply_to_obj(subj, obj_path, f, f_inputs);
%
%  See also apply_to_subj, apply_to_subj_obj, apply_to_ev, apply_to_pat.

% input checks
if ~exist('s', 'var')
  error('You must pass an object whose child object you want to modify.')
end

% backwards compatibility
if ischar(varargin{1}) && ischar(varargin{2})
  obj_path = varargin(1:2);
  varargin = varargin(3:end);
else
  obj_path = varargin{1};
  varargin = varargin(2:end);
end
if length(varargin) > 2
  error(['Not expecting more than four inputs, or five inputs for the old ' ...
         'version.'])
end

[fcn_handle, fcn_inputs] = varargin{:};

if ~exist('obj_path')
  error('You must specify the path to an object.')
elseif ~iscellstr(obj_path) || mod(length(obj_path),2) ~= 0
  error('obj_path must be a cell array of obj_type, obj_name pairs.')
elseif ~exist('fcn_handle', 'var')
  error('You must specify a function to run.')
end
if ~exist('fcn_inputs', 'var')
  fcn_inputs = {};
end

% if we error out, return the unmodified structure
s_out = s;

% get the object we want to modify
try
  obj = getobj(s, obj_path{:});
catch
  % couldn't find it
  warning('%s object %s not found.', obj_path{end-1}, obj_path{end})
  return
end

% set the source field of the object
obj.source = get_obj_name(s);

% run the function
obj = fcn_handle(obj, fcn_inputs{:});

% update the structure with the modified object
s_out = setobj(s, obj_path{1:end-1}, obj);
