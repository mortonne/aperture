function [pat, coeff] = patPCA(pat, params)
%PATPCA   Get principal components of a pattern.
%
%  [pat, coeff] = patPCA(pat, params)
%
%  INPUTS:
%      pat:  a pattern object.
%
%   params:  structure that specifies options for running PCA.  See 
%            below.
%
%  OUTPUTS:
%      pat:  a modified pattern object.
%
%    coeff:  coefficients of the principal components.
%
%  PARAMS:
%   nComp - number of principal components to return
%   scree - if true, make a scree plot of variance explained
%
%  See also modify_pattern.

% input checks
if ~exist('pat','var') || ~isstruct(pat)
  error('You must pass a pattern object.')
end
if ~exist('params','var')
	params = struct;
elseif isempty(params.nComp) || ~isnumeric(params.nComp)
  error('nComp must be numeric.')
end

params = structDefaults(params, ...
                        'nComp', 150,  ...
                        'scree', false);

pat_loc = get_obj_loc(pat);
pat = move_obj_to_workspace(pat);

% flatten all dimensions after events into one vector
pat_size = size(pat.mat);
pat.mat = reshape(pat.mat, [pat_size(1) prod(pat_size(2:end))]);

% deal with any nans in the pattern (variables may be thrown out)
pat.mat = remove_nans(pat.mat);

fprintf('getting first %d principal components...\n', params.nComp)
% get principal components
[coeff, pat.mat, latent] = princomp(pat.mat, 'econ');

if params.scree
  scree(latent);
end

%coeff = coeff(1:params.nComp,1:params.nComp);
pat.mat = pat.mat(:,1:params.nComp);

% update the pat object
pat.dim.chan = struct;
for c=1:size(pat.mat,2)
	pat.dim.chan(c).number = c;
	pat.dim.chan(c).region = '';
	pat.dim.chan(c).label = sprintf('Component %d', c);
end
pat.dim.time = init_time();
pat.dim.freq = init_freq();

% update the pattern
if strcmp(pat_loc, 'hd')
  pat = move_obj_to_hd(pat);
else
  pat.modified = true;
end

function scree(variance)
  explained = variance/sum(variance);
  cum = NaN(size(explained));
  opt = [];
  for i=1:length(explained)
    cum(i) = sum(explained(1:i));
  end
  plot(cum, '-k', 'LineWidth',3);
  xlabel('Number of Principal Components')
  ylabel('Variance Explained')
  publishfig
  drawnow
%endfunction
