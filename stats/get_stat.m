function x = get_stat(stat, name, index)
%GET_STAT   Get a variable from a statistics object.
%
%  x = get_stat(stat, name, index)
%
%  INPUTS:
%     stat:  a statistics object.
%
%     name:  name of the variable to load.
%
%    index:  (optional) the index of the variable to load. May be either
%            an index for referencing the variable matrix or a string
%            or cell array of strings giving the name(s) to load (must
%            be a "names" cell array of strings in stat.file)

% load the variable
x = getfield(load(stat.file, name), name);

% get the right index
if exist('index', 'var')
  if isnumeric(index) || islogical(index)
    x = x(index,:,:,:);
  elseif ischar(index)
    load(stat.file, 'names')
    match = ismember(names, index);
    if isempty(match)
      error('no variables named ''%s'' in file: %s', index, stat.file)
    end
    x = x(match,:,:,:);
  else
    error('invalid index')
  end
end

