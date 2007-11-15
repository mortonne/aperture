function pat = loadPat(patFile, masks)
%pat = loadPat(patFile, masks)
%
%LOADPAT - loads one subjects pattern, and applies any specified
%masks before passing it out
%

load(patFile)

if exist('masks', 'var') & ~isempty(masks)
  n = 1;
  for m=1:length(mask)
    if isempty(mask(m).name)
      continue
    else
      new(n) = mask(m);
      n = n + 1;
    end
  end
  mask = new;
  
  mask = filterStruct(mask, 'ismember(name, varargin{1})', masks);
  for m=1:length(mask)
    pat.mat(mask(m).mat) = NaN;
  end
end
