function new_pat = create_acts_pattern(pat, stat_name, new_pat_name, res_dir)
%CREATE_ACTS_PATTERN   Create a pattern from classifier outputs.
%
%  new_pat = create_acts_pattern(pat, stat_name, new_pat_name, res_dir)
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
%                 results of cross-validation pattern classification.
%
%  new_pat_name:  string name of the new pattern that will be created.
%
%       res_dir:  path to the directory where the pattern will be saved.
%                 If not specified, a directory named new_pat_name
%                 on the same level as pat's will be used.
%
%  OUTPUTS:
%       new_pat:  the new pattern object.

% input checks
if ~exist('res_dir', 'var')
  pat_parent_dir = fileparts(get_pat_dir(pat));
  res_dir = fullfile(pat_parent_dir, new_pat_name);
end

% get the results of pattern classification
stat = getobj(pat, 'stat', stat_name);
res = getfield(load(stat.file, 'res'), 'res');

% size of the new pattern is events X [dimensions of res]
res_size = size(res.iterations);
new_pat_size = [patsize(pat.dim, 1) res_size(2:end)];
pattern = NaN(new_pat_size, 'single');

% create a pattern with classifier outputs
for c=1:new_pat_size(2)
  for t=1:new_pat_size(3)
    for f=1:new_pat_size(4)
      
      for i=1:res_size(1)
        iter_res = res.iterations(i,c,t,f);
        corr = iter_res.acts(logical(iter_res.targs));
        pattern(iter_res.test_idx,c,t,f) = corr;
        %pattern(iter_res.test_idx,c,t,f) = iter_res.perf;
      end
      
    end
  end
end

% set the new pattern's file
pat_dir = fullfile(res_dir, 'patterns');
if ~exist(pat_dir, 'dir')
  mkdir(pat_dir)
end

new_pat_file = fullfile(pat_dir, ...
                        objfilename('pattern', new_pat_name, pat.source));

% create a new pat object (only name and file are different)
new_pat = init_pat(new_pat_name, new_pat_file, pat.source, stat.params, pat.dim);

% get the dimensions that we iterated over when doing classification
iter_dims = stat.params.iter_dims;
all_dims = 2:4;
non_iter_dims = all_dims(~ismember(all_dims, iter_dims));

% collapse the dimensions that were collapsed during classification
% (not including events)
for d=non_iter_dims
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

