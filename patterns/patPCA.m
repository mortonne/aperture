function [pat2, pattern, coeff] = patPCA(pat1, params, pattern, mask)
%function [pat2, pattern2, events2] = patBins(pat1, params, pattern1, events1, mask1)

params = structDefaults(params,  'masks', {}, 'loadSingles', 1);

if ~exist('pattern', 'var')
  % load the pattern from disk
  pattern = loadPat(pat1, params);
else
  % must apply masks manually
  for m=1:length(params.masks)
    thisMask = filterStruct(mask,'strcmp(name, varargin{1})', params.masks{m});
    pattern(thisMask.mat) = NaN;
  end
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
for c=1:size(pattern,2)
	pat2.dim.chan(c).number = c;
	pat2.dim.chan(c).region = '';
	pat2.dim.chan(c).label = sprintf('Component %d', c);
end
pat2.dim.time = init_time();
pat2.dim.freq = init_freq();
