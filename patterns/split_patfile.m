function [pat,err] = split_patfile(pat,dimname)
%[pat,err] = split_patfile(pat,dimname)
%
%   Note: this currently keeps the full pattern file, and just changes
%   the references in pat.file.
%

if ~exist('dimname','var')
  dimname = 'chan';
end

err = 0;

% load the pattern to be split
[pathstr,filename] = fileparts(pat.file);
err = prepFiles(pat.file,{});
if err
  return
end
fullpattern = loadPat(pat);

switch dimname
  case {'ev','events'}
  dimname = 'ev';
  d = 1;
  case 'chan'
  d = 2;
  case 'time'
  d = 3;
  case 'freq'
  d = 4;
  otherwise
  error('%s not valid dimension name.', dimname)
end
pat.dim.splitdim = d;

% split the pattern along the specified dimension
fprintf('splitting pattern %s along %s dimension: ', pat.name, dimname)
labels = {pat.dim.(dimname).label};
alldim = {':',':',':',':'};
dimlen = size(fullpattern,d);
pat.file = cell(1,dimlen);
for i=1:dimlen
  fprintf('%s ', labels{i})
  % get this slice
  ind = alldim;
  ind{d} = i;
  pattern = fullpattern(ind{:});
  
  % save to disk
  pat.file{i} = fullfile(pathstr,sprintf('%s_%s%s.mat',filename,dimname,labels{i}));
  save(pat.file{i},'pattern')
end
