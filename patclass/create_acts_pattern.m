function new_pat = create_acts_pattern(pat, stat_name, new_pat_name, ...
                                       varargin)
%CREATE_ACTS_PATTERN   Create a pattern from classifier outputs.
%
%  new_pat = create_acts_pattern(pat, stat_name, new_pat_name, ...)
%
%  From the results of pattern classification, get the classifier
%  output for the target on each trial, and put it in a new pattern.
%  The classifier output can then be manipulated and plotted in all of
%  the ways that any other pattern can.
%
%  INPUTS:
%           pat:  a pattern object.
%
%     stat_name:  name of a stat object attached to pat that contains
%                 results of pattern classification (created using
%                 classify_pat or classify_pat2pat).
%
%  new_pat_name:  string name of the new pattern that will be created.
%
%  OUTPUTS:
%       new_pat:  the new pattern object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   stat_type - the type of classification statistic to include in the
%               pattern. Can be:
%                'acts'    - value of the output unit for the actual
%                            condition
%                'guess'   - condition guessed by the classifier
%                'correct' - logical array indicating whether the
%                            classifier was correct. (default)
%   dim       - [currently not implemented] allows making a pattern from
%               non-scalar classification statistics; specifies the
%               dimension along which to extend the added statistic. (2)
%   precision - precision of the created pattern. [{'single'} | 'double']
%   res_dir   - directory in which to save the new pattern. Default is
%               a directory on the same level as the parent of pat.file,
%               named new_pat_name.

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must pass a pattern object.')
elseif ~exist('stat_name', 'var') || ~ischar(stat_name)
  error('You must pass the name of the stat object to use.')
end
if ~exist('new_pat_name', 'var')
  new_pat_name = sprintf('%s-%s', pat.name, stat_name);
end

% set params
defaults.stat_type = 'correct';
defaults.dim = 2;
defaults.precision = 'single';
defaults.res_dir = fullfile(fileparts(get_pat_dir(pat)), new_pat_name);

params = propval(varargin, defaults);

% get the results of pattern classification
stat = getobj(pat, 'stat', stat_name);
res = getfield(load(stat.file, 'res'), 'res');

% size of the new pattern is events X [dimensions of res]
res_size = size(res.iterations);
new_pat_size = [patsize(pat.dim, 1) 1 1 1];
new_pat_size(2:length(res_size)) = res_size(2:end);
pattern = NaN(new_pat_size, params.precision);

% create a pattern with classifier outputs
fprintf('creating "%s" pattern from "%s" classification results...\n', ...
        new_pat_name, stat_name)

for c=1:new_pat_size(2)
  for t=1:new_pat_size(3)
    for f=1:new_pat_size(4)
      pattern(:,c,t,f) = get_acts(res.iterations(:,c,t,f), params);
    end
  end
end

% set the new pattern's file
pat_dir = fullfile(params.res_dir, 'patterns');
if ~exist(pat_dir, 'dir')
  mkdir(pat_dir)
end

new_pat_file = fullfile(pat_dir, ...
                        objfilename('pattern', new_pat_name, pat.source));

% create a new pat object (only name and file are different)
new_pat = init_pat(new_pat_name, new_pat_file, pat.source, stat.params, ...
                   pat.dim);

% get non-singleton dimentions of res
non_sing = find(res_size > 1);
all_dims = 2:4;
sing_dims = all_dims(~ismember(all_dims, non_sing));

% collapse the dimensions that were collapsed during classification
% (not including events)
for d=sing_dims
  dim_name = read_dim_input(d);
  switch dim_name
   case 'chan'
    dim = struct('number',[], 'region','', 'label','');
   case 'time'
    dim = init_time(1);
   case 'freq'
    dim = init_freq(1);
   otherwise
    error('Unknown dimension type: %s.', dim_name)
  end
  
  new_pat.dim.(dim_name) = dim;
end

% add the classifier outputs as the pattern matrix
new_pat = set_mat(new_pat, pattern);

function acts = get_acts(res, params)
  n_events = length(res(1).test_idx);
  acts = NaN(n_events, 1);
  
  for i=1:length(res)
    iter_res = res(i);
    
    if strcmp(params.stat_type, 'acts')
      % get classifier activation for the correct unit
      mat = iter_res.acts(logical(iter_res.targs));
      
    elseif strcmp(params.stat_type, 'correct')
      % for each event, get whether the classifier guessed correctly
      perfmet = perfmet_maxclass(iter_res.acts, iter_res.targs);
      mat = perfmet.corrects;
      
    elseif strcmp(params.stat_type, 'guess')
      % for each event, get the unit that was maximally active
      perfmet = perfmet_maxclass(iter_res.acts, iter_res.targs);
      mat = perfmet.guesses;
    end

    acts(iter_res.test_idx) = mat;
  end
%endfunction
