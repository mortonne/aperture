function y = collapse_struct(x)
%COLLAPSE_STRUCT   Collapse an array structure to a scalar.
%
%  y = collapse_struct(x)
%
%  INPUTS:
%        x:  array structure.
%
%  OUTPUTS:
%        y:  scalar structure with only the fields of x that are the
%            same for all elements.

% input checks
if ~isstruct(x)
  error('x must be a structure.')
end

fnames = fieldnames(x);

y = struct;
% salvage fields that all have the same value
for j = 1:length(fnames)
  fname = fnames{j};
  
  % capture data in a cell array (_always_ works)
  field = {x.(fname)};

  if iscellstr(field)
    % collapse using unique
    uniq_field = unique(field);
    if length(uniq_field) == 1
      y.(fname) = uniq_field{:};
    end
  else
    % if not a cell array of strings, cannot use unique unless we can
    % make a numeric vector
    if any(cellfun(@isempty, field));
      % some empty fields; this can cause trouble, so for now not
      % dealing with this case
      continue
    end
    
    if ~(all(cellfun(@isnumeric, field)) || all(cellfun(@islogical, field)))
      % must leave this field off
      continue
    end
    
    % not simple to compare two arrays, so remove field if not
    % scalar
    if ~(all(cellfun(@isscalar, field)))
      continue
    end
    
    % NaNs are tricky, since each NaN is treated as unique
    n_nans = nnz(cellfun(@isnan, field));
    if n_nans == 0;
      uniq_field = unique([field{:}]);
      if length(uniq_field) == 1
        y.(fname) = uniq_field;
      end
    elseif n_nans == length(field)
      y.(fname) = NaN;
    end
  end
end

