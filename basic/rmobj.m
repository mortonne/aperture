function s = rmobj(s, varargin)
%RMOBJ   Remove an object from an object hierarchy.
%
%  INPUTS:
%         s:  structure containing an object that is to be removed.
%
%         f:  name of a field containing a list of objects.
%
%  obj_name:  name or cell array of names of the object(s) to be
%             removed. May also specify regular expression(s); all
%             patterns with matching names will be removed.
%
%  OUTPUTS:
%        s:  the modified structure, with the specified object deleted.
%
%  s = rmobj(s, f, obj_name)
%
%  Removes the object named obj_name of type f from s.
%
%  s = rmobj(s, f1, obj_name1, f2, obj_name2, ...)
%
%  Removes an arbitrarily nested object.  The last fieldname, objname
%  pair specifies the object to be removed.
%
%  See also getobj, setobj.

% input checks
if ~exist('s', 'var') || ~isstruct(s)
  error('You must pass a structure.')
elseif length(s) > 1
  error('Structure must be of length 1.')
elseif length(varargin) < 2
  error('Not enough input arguments.')
end

% unpack the arguments we need this round
[f, obj_name] = varargin{1:2};

if length(varargin)==2
  if ~iscell(obj_name)
    obj_name = {obj_name};
  end
  
  for i = 1:length(obj_name)
    n = 0;
    while true
      try
        % we've reached the object to delete
        [obj2rm, ind] = getobj(s, f, obj_name{i});

        % remove the object
        s.(f)(ind) = [];
        n = n + 1;
      catch
        % couldn't find it
        if n == 0
          fprintf('Warning: no object "%s" found in field "%s"\n', ...
                  obj_name{i}, f);
        end
        break
      end

    end    
  end

else
  % get the next object
  obj = getobj(s, f, obj_name);
  
  % call rmobj with this new object
  obj = rmobj(obj, varargin{3:end});
  
  % when we've finished climbing, unwind using setobj
  s = setobj(s, f, obj);
end
