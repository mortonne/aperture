function exp = bootstrap_all_subj(exp, pat_name, n_perm, reg_defs, ...
                                  stat_name, wilcox, event_bin_labels, ...
                                  save_as)
%BOOTSTRAP_ALL_SUBJ   Performs a bootstrap analysis across subjects.
%
%  exp = bootstrap_all_subj(exp, pat_name, n_perm, reg_defs, ...
%                           stat_name, wilcox)
%
%  INPUTS:
%         exp:  eeg_ana experiment object
%    pat_name:  pattern on which to perform bootstrap analysis
%      n_perm:  number of permutations to run (1000)
%    reg_defs:  event bins to compare, see make_event_index.  No
%               more than 2 event bins expected  ('overall')
%   stat_name:  name of stat object ('bootstrap')
%      wilcox:  do non-parametric test (true)
%
%  OUTPUT:
%         exp:  updated eeg_ana experiment structure, with grand
%               average pat object with corresponding bootstrap
%               stat object for the bootstrap analysis, containing
%               the following values:
%                 p:         observed cumulative probability of
%                            summed z-values from data
%                 zsum_sig:  observed summed z-values across subjects
%                 zsum_boot: distribution of summed z-values
%
%  See Sederberg et al., 2006 for procedure.
%
%  See also pat_bootstrap.


% input checks
if ~exist('exp','var')
  error('You must pass an experiment structure.')
end
if ~exist('pat_name','var')
  error('You must pass a pat_name on which to perform the bootstrap.')
end

if ~exist('n_perm','var')
  n_perm = 1000;
end

if ~exist('reg_defs','var') || isempty(reg_defs)
  reg_defs = 'overall';
  paired = 1;
elseif strcmp(reg_defs,'overall')
  paired = 1;
else
  paired = 0;
end

if ~exist('stat_name','var')
  stat_name = 'bootstrap';
end
if ~exist('wilcox','var')
  wilcox = true;
end
if ~exist('save_as')
  save_as = pat_name;
end

% check if subject level analysis has already been run
try
  getobj(exp.subj(1), 'pat', pat_name, 'stat', stat_name);
catch
  % run subj level stuff
  exp.subj = apply_to_pat(exp.subj, pat_name, @pat_bootstrap, {n_perm, ...
                      reg_defs, stat_name, wilcox}, 1, 'walltime', '00:30:00');
end

if ~exist('event_bin_labels', 'var')
  % make some dummy labels
  try
    % determine number of labels to make using first subject
    pat = getobj(exp.subj(1), 'pat', pat_name);
    events = get_mat(pat.dim.ev);
    [ind, lvls] = make_event_index(events, reg_defs);
    n_bins = length(lvls);
    
    % create the appropriate number of labels
    event_bin_labels = cell(1,n_bins);
    for b=1:n_bins
      event_bin_labels{b} = sprintf('bin%d', b);
    end
    
  catch
    % something went wrong, assume default labels
    event_bin_labels = {};
  end
end

% grandavg pat
pat = cat_all_subj_patterns(exp.subj, pat_name, 1, ...
                            {'event_bins', reg_defs, ...
                    'event_bin_labels', event_bin_labels, ...
                    'dist', 0, ...
                    'save_mats', false});

label_reg_defs = cell(1,length(event_bin_labels));
for b=1:length(event_bin_labels)
  label_reg_defs{b} = ['strcmp(label, ''' event_bin_labels{b} ''')'];
end

pat = bin_pattern(pat, {'eventbins', label_reg_defs, ...
                    'eventbinlabels', event_bin_labels, ...
                    'save_mats', true, ...
                    'save_as', save_as, ...
                    'overwrite', true});

exp = setobj(exp, 'pat', pat);

% initialize the stat object
stat_file = fullfile(get_pat_dir(pat, 'stats'), ...
                     objfilename('stat', stat_name, pat.source));
p = struct;
p.n_perm = n_perm;
p.reg_defs = reg_defs;
p.wilcox = wilcox;
p.paired = paired;

stat = init_stat(stat_name, stat_file, pat.source, p);

% generate stat
n_subj = length(exp.subj);

p_sig = cell(1,n_subj);
p_boot = cell(1,n_subj);

% collect subject stats
for s = 1:n_subj
  subj_stat = getobj(exp.subj(s), 'pat', pat_name, 'stat', stat_name);
  p_sig{s} = get_stat(subj_stat, 'p_sig');
  p_boot{s} = get_stat(subj_stat, 'p_boot');
end

% unbound p-values
p_sig = cellfun(@unbound_pvals, p_sig, 'UniformOutput', false);
p_boot = cellfun(@unbound_pvals, p_boot, 'UniformOutput', false);

% z-score the values
z_sig = cellfun(@norminv, p_sig, 'UniformOutput', false);
z_boot = cellfun(@norminv, p_boot, 'UniformOutput', false);

% sum the z-scores across subjects
zsum_sig = nansum(cat(4,z_sig{:}),4);
zsum_boot = nansum(cat(5,z_boot{:}),5);


% determine the empirical p-value based on the distribution
p = NaN(size(zsum_sig));
dist_size = prod(size(zsum_boot));
[chan,time,freq] = size(zsum_sig);

for c = 1:chan
  for t = 1:time
    for f = 1:freq
      p(c,t,f) = nansum(zsum_boot(:) < zsum_sig(c,t,f)) ...
	      / nansum(~isnan(zsum_boot(:)));
    end
  end
end

% save the results
save(stat.file, 'p', 'zsum_sig', 'zsum_boot');
pat = setobj(pat, 'stat', stat);
exp = setobj(exp, 'pat', pat);



function p_out = unbound_pvals(p_in)
%UNBOUND_PVALS  Set a minimum value for p-vals
%
%  p_out = unbound_pvals(p_in)
%
%  norminv has certain thresholds past which values are not
%  defined.  This function sets p-values within that threshold by
%  using the value eps.

p_out = p_in;
p_out(p_out==0) = eps;
p_out(p_out==1) = 1-eps;
      
      
      
      
      
      
      
