function s = print_obj(subobj, obj_type, long_name, dim_labels, obj_names, ...
                       varargin)
%PRINT_OBJ   Print a string description of an object.
%
%  s = print_obj(subobj, obj_type, long_name, dim_labels, obj_names, args)
%
%  INPUTS:
%      subobj:  structure with a subfield containing the object(s) to be
%               printed.  Can be a vector or a scalar structure.
%
%    obj_type:  string indicating the type of object.
%
%   long_name:  string giving the long name of the object, to be printed
%               in the header.
%
%  dim_labels:  cell array of strings giving a label for each dimension
%               of the object(s).
%
%   obj_names:  cell array of strings giving the names of the objects to
%               be printed.  Also determines the order in which objects
%               are printed.  If not specified, all objects will be
%               printed, in the order they are listed on subobj.
%
%  ARGS:
%  Optional additional arguments passed in as parameter, value pairs:
%   col1_width - width of the first column in characters. (30)
%   id_f       - formatting string for the identifier field. ('%6i %s')
%
%  OUTPUTS:
%   The first column gives the index of the object in the list, and the
%   object's name.  The second column displays the object's size.  The
%   dimensions vary depending on the type of object.  If there are
%   multiple objects, each dimension will be printed as NaN unless it is
%   the same for all of the objects in the list.
%
%  NOTES:
%   Currently, only 'subj', 'ev', and 'pat' objects are supported.

% input checks
if ~exist('obj_names', 'var')
  if isscalar(subobj)
    obj_names = arrayfun(@get_obj_name, subobj.(obj_type), ...
                         'UniformOutput', false);
  else
    error('If subobj is not a scalar, you must pass object names.')
  end
end

% set formatting
defaults.col1_width = 30;
defaults.id_f = '%6i) %s';
params = propval(varargin, defaults);

col1_f = sprintf('%%-%is', params.col1_width);

% get the max length for the dimension column
all_obj_sizes = {};
for i=1:length(obj_names)
  % get size strings for each dimension
  obj_size = get_obj_size(subobj, obj_type, obj_names{i});
  all_obj_sizes = [all_obj_sizes; obj_size];
end
all_dim_labels = [dim_labels all_obj_sizes(:)'];
max_dim_len = max(cellfun(@length, all_dim_labels));

% print the formatting for the header  
f = sprintf('%%%is', max_dim_len);
head_dim_f = print_dim_f(length(dim_labels), f);
head_dim = sprintf(head_dim_f, dim_labels{:});

% print the header
head_f = sprintf('%s%s\n', col1_f, head_dim);
head = sprintf(head_f, [long_name ' -']);

% print the formatting for the body dim column
f = sprintf('%%%is', max_dim_len);
body_dim_f = print_dim_f(length(dim_labels), f);

body = '';
for i=1:length(obj_names)
  % get size strings for each dimension
  obj_dim = sprintf(body_dim_f, all_obj_sizes{i,:});

  % print the line for this object
  obj_id = sprintf(params.id_f, i, obj_names{i});
  obj_f = sprintf('%s%s\n', col1_f, obj_dim);
  obj = sprintf(obj_f, obj_id);

  body = [body obj];
end

s = [head body '\n'];

function s = print_dim_f(n, f)
  %PRINT_DIM_F   Print size in [n x n x n ...] format.
  %
  %  s = print_dim_f(n, f)
  
  s = '[';
  for i=1:n-1
    s = [s f ' x '];
  end
  s = [s f ']'];
%endfunction

function obj_size = get_obj_size(subobj, obj_type, obj_name)
  %GET_OBJ_SIZE   Get the size of an object.
  %
  %  obj_size = get_obj_size(subobj, obj_type, obj_name)

  % initialize the size matrix [n_obj X dims]
  switch obj_type
   case 'pat'
    obj_sizes = NaN(length(subobj), 4);
   case 'ev'
    obj_sizes = NaN(length(subobj), 1);
   case 'subj'
    obj_sizes = NaN(length(subobj), 2);
   otherwise
    error('Cannot determine size for object type: %s.', obj_type)
  end

  % get the size of each object
  for i=1:length(subobj)
    obj = getobj(subobj(i), obj_type, obj_name);
    
    switch obj_type
     case 'pat'
      obj_sizes(i,:) = patsize(obj.dim);
     case 'ev'
      obj_sizes(i) = obj.len;
     case 'subj'
      obj_sizes(i,1) = length(obj.sess);
      obj_sizes(i,2) = length(obj.chan);
    end
  end
  
  % make sure the size of each dimension is unique; if not, set it to NaN
  obj_size = cell(1, size(obj_sizes,2));
  for i=1:size(obj_sizes,2)
    uniq_dim_size = unique(obj_sizes(:,i));
    if length(uniq_dim_size) > 1
      obj_size{i} = sprintf('%i-%i', min(uniq_dim_size), max(uniq_dim_size));
    else
      obj_size{i} = sprintf('%i', uniq_dim_size);
    end
  end
%endfunction

