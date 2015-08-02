function s = merge_structs(varargin)
% MERGE_STRUCTS   Merge the values on multiple structures
%   s = merge_structs(s1, s2, s3, ...)
%   
%  merge_structs creates a new structure with the set of unique
%  field names from each of its inputs.  The value of each field is
%  taken from the first structure in the inputs that has a field of
%  that name.  
% 
%  EXAMPLES:
%  >> s1.f1 = 'val'; s2.f2 = 'VAL';
%  >> s = merge_structs(s1, s2);
%  s =
%      f1: 'val'
%      f2: 'VAL'
% 
%  >> s1.f2 = 'f2 is no longer taken from s2';
%  >> s = merge_structs(s1, s2);
%  s = 
%      f1: 'val'
%      f2: 'f2 is no longer taken from s2'

% sanity checks
if length(varargin) == 0
  error('Nothing to merge!')
end
for i = 1:length(varargin)
  if ~isstruct(varargin{i})
    error(sprintf('Argument %d is not a structure', i))
  elseif length(varargin{i}) > 1
    error(sprintf('Argument %d is a structure array', i))
  end
end

% get all the field names in one cell array
all_fields = cell(1, 0);
for i = 1:length(varargin)
  s_fields = fieldnames(varargin{i});
  num_fields = size(s_fields, 1);
  all_fields = [all_fields, reshape(s_fields, [1, num_fields])];
end
all_fields = unique(all_fields);

% create the merged structure, taking the value for each field from
% the first input that has that field
s = struct;
for j = 1:length(all_fields)
  field = all_fields{j};
  for k = 1:length(varargin)
    s_k = varargin{k};
    if isfield(s_k, field)
      s.(field) = s_k.(field);
      break
    end
  end
end

      
  
  
