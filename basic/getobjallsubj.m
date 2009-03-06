function objs = getobjallsubj(subj,path)
%GETOBJALLSUBJ   Get objects from multiple subjects.
%
%  objs = getobjallsubj(subj, path)
%
%  INPUTS:
%       subj:  a structure representing each subject in an experiment. 
%
%       path:  cell array giving the path to an object on each subj
%              structure in exp. Form must be:
%               {t1,n1,...}
%              where t1 is an object type (e.g. 'pat', 'stat'),
%              and n1 is the name of an object.
%
%  OUTPUTS:
%       objs:  an array of objects.
%
%  EXAMPLES:
%   % to get a pat object named 'voltage' from every subject
%   pats = getobjallsubj(subj, {'pat', 'voltage'});

% input checks
if ~exist('subj','var')
  error('You must pass a subj structure.')
  elseif ~isstruct(subj)
  error('subj must be a structure.')
  elseif ~isfield(subj,'id')
  error('subj must have an id field.')
end
if ~exist('path','var')
  path = {};
end

fprintf('Exporting from subjects...\n')

% first make a subjects X variables cell array
n = 1;
for s=1:length(subj)
  fprintf('%s\n', subj(s).id)

  % get the object for this subject
  obj = getobj2(subj(s),path);

  if isempty(obj)
    % we couldn't find an object corresponding to that path
    fprintf('Warning: object %s not found.', path{end})
    continue
  end

  % add to the array
  objs(n) = obj;
  n = n + 1;
end
