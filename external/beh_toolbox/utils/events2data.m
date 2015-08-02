function [data] = events2data(events,index,index_rows)
%EVENTS2DATA   Convert an events struct to matrix format.
%
%  data = events2data(events, index, index_rows)
%
%  INPUTS:
%      events:  a vector structure. Each field in events will be converted
%               to matrix format and placed in the data structure. Each
%               field can have any datatype. If all values of a given field
%               are numeric, the field will become a numeric array in the
%               data structure; otherwise, the corresponding field in data
%               will be a cell array.
%
%       index:  vector of the same length as events; events corresponding to
%               each unique value will be placed in one row in the returned 
%               data structure.
%
%  index_rows:  vector with at least one element for each unique value of
%               index. The position of each value in the vector indicates 
%               which row each unique value of index will be placed,
%               e.g. [2 3] to place events with index=2 in row 1, and 
%               events with index=3 in row 2.
%               If not specified, unique(index) will be used.
%
%  OUTPUTS:
%        data:  structure with one field for each field in the events
%               structure. Each field holds a matrix that has one row
%               for each value of index, and each matrix has the
%               same number of columns; if any rows are shorter than
%               than the maximum row length, they will be padded with
%               zeros or empty cells, depending on the datatype of that
%               field.
%
%  EXAMPLE:
%   % create an events structure with four events
%   [events(1:4).subject] = deal('subj00');
%   [events(1:2).trial] = deal(2);
%   [events(3:4).trial] = deal(3);
%
%   % convert to data structure format, omitting trial 1
%   data = events2data(events, [events.trial]);
%
%   % now the missing trial 1 will be put in the data structure,
%   % with zeros/empty cells used for padding
%   data = events2data(events, [events.trial], 1:3)

% input checks
if ~exist('events','var') || ~isstruct(events)
  error('You must input an events structure.')
elseif ~exist('index','var') || ~isnumeric(index)
  error('You must input a numeric index.')
elseif length(index)~=length(events)
  error('index must be the same length as events.')
elseif any(isnan(index))
  error('index contains NaNs.')
end

% change index to a column vector so apply_by_index won't get upset
if size(index, 2) > 1
  index = index';
end
uniq_index = unique(index);

% set the order of rows in the final matrices
if ~exist('index_rows','var')
  index_rows = uniq_index;
elseif ~isempty(setdiff(uniq_index, index_rows))
  error('index_rows must include every value in index.')
end

% get the row for each index in terms of all possible indices
[c,indices,rows] = intersect(uniq_index, index_rows);

% get maximum row length
max_row_length = max([collect(index, uniq_index') 1]);

% convert each field to matrix format and add to the data structure
field_names = fieldnames(events);
for i = 1:length(field_names)
  f = field_names{i};
  
  % put all the values of this field into a cell array
  field = {events.(f)}';
  vectorizable = ~any(cellfun(@isempty, field)) & ...
                 all(cellfun(@isnumeric, field) | cellfun(@islogical, field));
  if vectorizable
    % make it a vector
    field = [field{:}]';
    data.(f) = zeros(length(index_rows), max_row_length);
  else
    % use a cell array
    data.(f) = cell(length(index_rows), max_row_length);
  end
  
  if ~isempty(field)
    % make a matrix with one row for each unique value of index, padding
    % as needed with zeros or empty cells
    matrix = apply_by_index(@make_padded_row, index, 1, {field}, ...
                            max_row_length);
    
    % place the returned rows in the right spots
    data.(f)(rows,:) = matrix;
  end
end


function row_vector = make_padded_row(column_vector, final_length)
  if iscell(column_vector)
    row_vector = cell(1,final_length);
  else
    row_vector = zeros(1,final_length);
  end

  row_vector(1,1:length(column_vector)) = column_vector;
%endfunction
