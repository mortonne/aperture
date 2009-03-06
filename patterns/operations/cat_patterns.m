function pat = cat_patterns(pats,dimension,pat_name,res_dir)
%CAT_PATTERNS   Concatenate a set of patterns.
%
%  pat = cat_patterns(pats, dimension, pat_name, res_dir)
%
%  INPUTS:
%       pats:  a vector of pat objects.
%
%  dimension:  dimension along which to concatenate the patterns.
%              Can be either a string specifying the name of the 
%              dimension (can be: 'ev', 'chan', 'time', 'freq'), 
%              or an integer corresponding to the dimension in the 
%              actual matrix.
%
%   pat_name:  string identifier for the new pattern.
%
%    res_dir:  directory where the new pattern will be saved.
%
%  OUTPUTS:
%        pat:  pat object with metadata for the new concatenated
%              pattern.

% input checks
if ~exist('pats','var')
  error('You must pass a vector of pat objects.')
end
if ~exist('dimension','var')
  dimension = 2;
end
if ~exist('pat_name','var')
  pat_name = 'cat_pattern';
end
if ~exist('res_dir','var')
  % get the path to the pattern's file
  if iscell(pats(1).file)
    pat_file = pats(1).file{1};
    else
    pat_file = pats(1).file;
  end
  % set the default results directory
  res_dir = fileparts(pat_file);
end

% parse the dimension input
[dim_name, dim_number] = read_dim_input(dimension);

% get the dimension sizes of each pattern
n_dims = 4;
pat_sizes = NaN(length(pats), n_dims);
for i=1:length(pats)
  pat_sizes(i,:) = patsize(pats(i).dim);
end
% make sure the other dimensions match up
for j=1:n_dims
  if dim_number~=j && any(pat_sizes(2:end,j)~=pat_sizes(1,j))
    error('Dimension %d does not match for all patterns.', j)
  end
end

% concatenate the dim structure
dim = pats(1).dim;
if strcmp(dim_name, 'ev')
  % load each events structure
  fprintf('Concatenating events...')
  events = [];
  for i=1:length(pats)
    fprintf('%s ', pats(i).source)
    events = [events load_events(pats(i).dim.ev)];
  end
  fprintf('\n')

  % save the concatenated events
  ev_dir = fullfile(res_dir, 'events');
  if ~exist(ev_dir)
    mkdir(ev_dir);
  end
  dim.ev.file = fullfile(ev_dir, sprintf('events_%s_multiple.mat', pat_name));
  save(dim.ev.file, 'events')
  if isfield(dim.ev,'mat')
    dim.ev.mat = events;
  end
  
  % update the ev object
  dim.ev.source = 'multiple';
  dim.ev.len = length(events);
  
  else
  % we can just concatenate
  dims = [pats.dim];
  dim.(dim_name) = [dims.(dim_name)];
end

% concatenate the pattern
fprintf('Concatenating patterns...')
pattern = [];
for i=1:length(pats)
  fprintf('%s ', pats(i).source)
  pattern = cat(dim_number, pattern, load_pattern(pats(i)));
end
fprintf('\n')

% save the new pattern
pat_dir = fullfile(res_dir, 'patterns')
if ~exist(pat_dir)
  mkdir(pat_dir)
end
pat_file = fullfile(pat_dir, sprintf('pattern_%s_multiple.mat', pat_name));
save(pat_file, 'pattern')

% create the new pat object
pat = init_pat(pat_name, pat_file, 'multiple', pats(1).params, dim);
