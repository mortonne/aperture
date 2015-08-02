function recalls = make_recalls_matrix(pres_itemnos, rec_itemnos)
%MAKE_RECALLS_MATRIX   Make a standard recalls matrix.
%
%  Given presented and recalled item numbers, finds the position of
%  recalled items in the presentation list. Creates a standard
%  recalls matrix for use with many toolbox functions.
%
%  recalls = make_recalls_matrix(pres_itemnos, rec_itemnos)
%
%  INPUTS:
%  pres_itemnos:  [trials X items] matrix of item numbers of
%                 presented items. Must be positive.
%
%   rec_itemnos:  [trials X recalls] matrix of item numbers of recalled
%                 items. Must match pres_itemnos. Items not in the
%                 stimulus pool (extra-list intrusions) should be
%                 labeled with -1. Rows may be padded with zeros or
%                 NaNs.
%
%  OUTPUTS:
%  recalls:  [trials X recalls] matrix. For recall(i,j), possible
%            values are:
%             >0   correct recall. Indicates the serial position in
%                  which the recalled item was presented.
%              0   used for padding rows. Corresponds to no recall.
%             <0   intrusion of an item not presented on the list.
%
%  EXAMPLE:
%   pres_itemnos = [1:5; 6:10; 11:15];
%   rec_itemnos = [5 1 2 3; 10 9 -999 0; 11 12 0 0];
%   recalls = make_recalls_matrix(pres_itemnos, rec_itemnos)
%
%   Returns:
%    5  1  2  3
%    5  4 -1  0
%    1  2  0  0

[n_trials, n_items] = size(pres_itemnos);
n_recalls = size(rec_itemnos, 2);
recalls = zeros(n_trials, n_recalls);
for i = 1:n_trials
  for j = 1:n_recalls
    if rec_itemnos(i,j) == 0 || isnan(rec_itemnos(i,j))
      % nothing recalled, so just skip
      continue
      
    elseif rec_itemnos(i,j) > 0
      % have some item number recorded; look for it in the
      % presentation list
      serialpos = find(rec_itemnos(i,j) == pres_itemnos(i,:));
      if length(serialpos) > 1
        error(['Item %d was presented multiple times in trial %d. ' ...
               'Presented serial position is undefined.'], ...
              rec_itemnos(i,j), i);
      elseif isempty(serialpos)
        % this was an intrusion
        recalls(i,j) = -1;
      else
        recalls(i,j) = serialpos;
      end
      
    else
      % some negative number; must not be in the stimulus pool
      recalls(i,j) = -1;
    end
  end
end

