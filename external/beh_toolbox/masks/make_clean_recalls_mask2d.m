function mask = make_clean_recalls_mask2d(recalls_matrix)
%MAKE_CLEAN_RECALLS_MASK2D  Exclude repeats and intrusions.
%
%  Makes a mask of the same shape as recalls_matrix which is false at 
%  positions (i,j) if recalls_matrix(i,j) is an intrusion, 
%  repeat, or empty cell.
%
%  mask = make_clean_recalls_mask2d(recalls_matrix)
  
% sanity:
if ndims(recalls_matrix) ~= 2
  error('recalls_matrix must be two-dimensional.')
end

mask = recalls_matrix>0; % Removes intrusions
% NOTE: it's more efficient to use this first step when eliminating
% repeats, rather than calling on the non-intrusion and non-repetition mask
% functions separately

%Finds all of the unique non-nan values in the matrix (will be 1:listLength)
unique_vals = unique(recalls_matrix(mask));
if iscolumn(unique_vals)
  unique_vals = unique_vals';
end
for val = unique_vals

    % Finds all occurences of the value
    locs = find(recalls_matrix==val);
    % Returns a row number for each occurence
    [rows,t1] = ind2sub(size(recalls_matrix),locs);
    % Returns the indices of the first occurence of each row
    [t1, unique_indices] = unique(rows, 'first'); 
    % Builds a list of all possible locations of values
    extra_y_indices = 1:length(rows); 
    % removes the locations that are not the first occurence
    extra_y_indices(~ismember(extra_y_indices, unique_indices)) = []; 
    % Locs now holds only the positions of repeated occurences 
    locs(extra_y_indices) = []; 
    mask(locs) = false;

end

%endfunction
