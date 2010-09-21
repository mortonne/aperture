function labels = get_dim_labels(dim_info, dim_id)
%GET_DIM_LABELS   Get the numeric values of a dimension.
%
%  labels = get_dim_labels(dim_info, dim_id)
%
%  INPUTS:
%  dim_info:  structure with information about the dimensions of a
%             pattern.  (normally stored in pat.dim).
%
%    dim_id:  either a string specifying the name of the dimension
%             (can be: 'ev', 'chan', 'time', 'freq'), or an integer
%             corresponding to the dimension in the actual matrix.
%
%  OUTPUTS:
%    labels:  cell array of string labels for the requested dimension.

% input checks
if ~exist('dim_info', 'var') || ~isstruct(dim_info)
  error('You must pass a dim info structure.')
elseif ~exist('dim_id', 'var')
  error('You must indicate the dimension.')
elseif ~(ischar(dim_id) || isnumeric(dim_id))
  error('dim_id must be a string or an integer.')
end

% get the short name of the dimension
dim_name = read_dim_input(dim_id);
dim = get_dim(dim_info, dim_name);

if strcmp(dim_name, 'ev')
  % potential fields with labels
  f = {'label', 'type'};
  f = f(ismember(f, fieldnames(dim)));
  labels = {};
  n = 0;
  while isempty(labels)
    n = n + 1;
    if n > length(f)
      break
    end
    labels = {dim.(f{n})};

    % if it's not unique, we don't want it
    if (iscellstr(labels) && ~isunique(labels)) || ...
       (~iscellstr(labels) && ~isunique([labels{:}]))
      labels = {};
      continue
    end
    
    % try to convert to a cell array of strings
    if ~iscellstr(labels)
      try
        labels = cellfun(@num2str, labels, 'UniformOutput', false);
      catch
        labels = {};
        continue
      end
    end
  end

  % if all else fails, just return the indices
  if isempty(labels)
    labels = cellfun(@num2str, num2cell(1:length(dim)), ...
                     'UniformOutput', false);
  end
else
  % use the label field
  labels = {dim.label};
end

