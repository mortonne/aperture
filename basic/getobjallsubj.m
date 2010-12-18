function objs = getobjallsubj(subj, varargin)
%GETOBJALLSUBJ   Get objects from multiple subjects.
%
%  objs = getobjallsubj(subj, ...)
%
%  INPUTS:
%       subj:  a structure representing each subject in an experiment. 
%
%   varargin:  specifies the location of an object by obj_type, obj_name
%              pairs.
%
%  OUTPUTS:
%       objs:  an array of objects.
%
%  EXAMPLES:
%   % to get a pat object named 'voltage' from every subject
%   pats = getobjallsubj(subj, 'pat', 'voltage');

% input checks
if ~exist('subj', 'var')
  error('You must pass a subj structure.')
elseif ~isstruct(subj)
  error('subj must be a structure.')
end

if ~isempty(varargin) && iscell(varargin{1})
  % old input format
  path = varargin{1};
else
  path = varargin;
end

%fprintf('exporting %s object %s from subjects...\n', path{end-1}, path{end})

objs = [];
for s=1:length(subj)
  %fprintf('%s ', subj(s).id)

  % get the object for this subject
  try
    obj = getobj(subj(s), path{:});
  catch
    obj = [];
  end

  if isempty(obj)
    % we couldn't find an object corresponding to that path
    fprintf('Warning: object %s not found.', path{end})
    continue
  end

  % add to the array
  if isempty(objs)
    objs = obj;
  else
    objs = cat_structs(objs, obj);
  end
end

if isempty(objs)
  error('no objects found.')
end

%fprintf('\n')
