function pat = expandDim(pat,dimname,dimnum,patname,resDir)
% EXPANDDIM   Intersperse dimensions to create one larger dimension.
%   [PAT] = EXPANDDIM(PAT,DIMNAME,DIMNUM,PATNAME)
%

% Created by Neal Morton on 2008-08-05.

if ~exist('resDir','var')
  [dir,filename] = fileparts(pat.file);
  resDir = fullfile(fileparts(fileparts(dir)), patname);
end
if ~exist('patname','var')
  patname = [pat.name '_mod'];
end

if length(dimname)~=length(dimnum)
  error('dimname and dimnum must be the same length.')
end
if ~iscell(dimname)
  dimname = {dimname};
end

for i=1:length(dimname)
  if strcmp(dimname{i}, 'ev') | strcmp(dimname{i}, 'events')
    load(pat.dim.ev.file);
    dim{i} = events(:)';
    
    else
    dim{i} = pat.dim.(dimname{i});
  end
end

psize = patsize(pat.dim);
newlen = prod(psize(dimnum));

i = 1;
ind = zeros(newlen,length(dim));
for d1=1:length(dim{1})
  for d2=1:length(dim{2})
    ind(i,1) = d1;
    ind(i,2) = d2;
    i = i + 1;
  end
end

events = combineStructs(dim{1}(ind(:,1)), dim{2}(ind(:,2)));

% abandoning generality
pat.dim.time = init_time();
pat.dim.ev.file = fullfile(resDir, 'events', objfilename('events', patname, pat.source));
pat.dim.ev.len = length(events);

prepFiles({},pat.dim.ev.file);
save(pat.dim.ev.file, 'events');

% load the pattern to change, with dimension order evXtimeXchanXfreq
old_pattern = permute(loadPat(pat), [1 3 2 4]);

% now deal with the pattern (ev/timeXchanXfreq)
pattern = NaN(newlen,psize(2),psize(4));
for i=1:size(ind,1)
  pattern(i,:,:) = squeeze(old_pattern(ind(i,1),ind(i,2),:,:));
end

if ~strcmp(pat.name, patname)
  % if the patname is different, save the pattern to a new file
  pat.name = patname;
  pat.file = fullfile(resDir, 'patterns', objfilename('pattern', patname, pat.source));
end

prepFiles({},pat.file);
save(pat.file, 'pattern');
