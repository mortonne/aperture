function [max_prop, norm_prop] = norm_list_prop(list_prop)
%NORM_LIST_PROP   Normalize a list of channel properties.
%
%  [max_prop, norm_prop] = norm_list_prop(list_prop)
%
%  INPUTS:
%  list_prop:  a [channels X properties] or a [channels X properties X epochs]
%              matrix of property values.
%
%  OUTPUT:
%   max_prop:  [channels X 1] or [channels X epochs] matrix indicating
%              the absolute maximum (over properties) of the normalized
%              value for each channel or channel-epoch.
%
%  norm_prop:  matrix the same size as list_prop with the normalized
%              value for each property.

if ndims(list_prop) == 2
  % assume [chans X props]
  prop_iqr = iqr(list_prop, 1);
  prop_med = nanmedian(list_prop, 1);
  n_obs = size(list_prop, 1);
  x = [n_obs 1 1];
  norm_prop = (list_prop - repmat(prop_med, x)) ./ repmat(prop_iqr, x);
else
  % assume [chans X props X events]
  mat = permute(list_prop, [2 1 3]);
  mat = mat(:,:);
  prop_iqr = iqr(mat, 2);
  prop_med = nanmedian(mat, 2);
  x = [size(list_prop, 1) 1 size(list_prop, 3)];
  norm_prop = (list_prop - repmat(prop_med', x)) ./ repmat(prop_iqr', x);
end

max_prop = permute(max(abs(norm_prop), [], 2), [1 3 2]);
