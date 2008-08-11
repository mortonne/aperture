function [pat2, pattern, coeff] = patPCA(pat1, params, pattern)
%
%PATPCA   Get principal components of a pattern.
%   [PAT2,PATTERN,COEFF] = PATPCA(PAT1,PARAMS,PATTERN) does PCA on PATTERN
%   according to options specified in the PARAMS struct.  The modified PAT2
%   gives meta-data on the new pattern.  COEFF contains the coefficients of
%   each principle component used.
%
%   OPTIONAL PARAMS:
%      nComp - number of principal components to return
%

if ~exist('params','var')
	params = struct;
end

params = structDefaults(params,  'nComp', 150,  'loadSingles', 1);

if ~exist('pattern', 'var')
  % load the pattern from disk
  pattern = loadPat(pat1, params);
end

% flatten all dimensions after events into one vector
patsize = size(pattern);
pattern = reshape(pattern, [patsize(1) prod(patsize(2:end))]);

% deal with any nans in the pattern (variables may be thrown out)
pattern = remove_nans(pattern);

if ~isempty(params.nComp)
	fprintf('getting first %d principal components...\n', params.nComp)
	% get principal components
	[coeff,pattern] = princomp(pattern,'econ');
	coeff = coeff(1:params.nComp,1:params.nComp);
	pattern = pattern(:,1:params.nComp);
end

% update the pat object
pat2 = pat1;
pat2.dim.chan = struct;
for c=1:size(pattern,2)
	pat2.dim.chan(c).number = c;
	pat2.dim.chan(c).region = '';
	pat2.dim.chan(c).label = sprintf('Component %d', c);
end
pat2.dim.time = init_time();
pat2.dim.freq = init_freq();
