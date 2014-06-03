function pat = pat_bootstrap(pat, n_perm, reg_defs, stat_name, wilcox)
%PAT_BOOTSTRAP  Perform a bootstrap procedure on a pattern object.
%
%  pat = pat_bootstrap(pat, n_perm, reg_defs, stat_name, wilcox)
%
%  INPUTS:
%         pat:  eeg_ana pattern object
%      n_perm:  number of permutations to run (1000)
%    reg_defs:  event bins to compare, see make_event_index.  No
%               more than 2 event bins expected  ('overall')
%   stat_name:  name of stat object ('bootstrap')
%      wilcox:  do non-parametric test (true)
%
%  OUTPUT:
%        stat:  updated pat object with stat object corresponding
%               bootstrap analysis, which contains the following
%               values:
%                 p_sig:    p-values for observed data
%                 p_boot:   p-values for shuffled data
%                 shuffles: permutation indices (not paired) or signs
%                           (paired)
%
%  See Sederberg et al., 2006 for procedure.
%
%  See also bootstrap_all_subj.

% input checks
if ~exist('pat','var')
  error('You must pass a pattern object.')
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
  wilcox = 1;
end

% determine test to do
if paired
  if wilcox
    % non parametric
    f_stat = @signrank_tail;
    f_inputs = {[], 'tail', 'right'};
    f_outputs = {'p', 'h', 'stats'};
  else
    % parametric
    f_stat = @ttest;
    f_inputs = {0, 0.05, 1};
    f_outputs = {'h','p','ci','stats'};
  end
else
  if wilcox
    %non parametric
    f_stat = @ranksum_ci;
    f_inputs = {0.05, 1};
    f_outputs = {'p','h','stats','Ws'};
  else
    % parametric
    f_stat = @ttest2;
    f_inputs = {0.05, 1};
    f_outputs = {'h','p','ci','stats'};
  end
end

p_out = find(strcmp(f_outputs,'p'));

if ~isempty(reg_defs)
  % load events for this pattern
  events = get_dim(pat.dim, 'ev');
  
  [group, levels] = make_event_index(events, reg_defs);
  clear events
else
  group = {};
  levels = {};
end

% initialize the stat object
stat_file = fullfile(get_pat_dir(pat, 'stats'), ...
                     objfilename('stat', stat_name, pat.source));
p = struct;
p.reg_defs = reg_defs;
p.wilcox = wilcox;
p.paired = paired;

stat = init_stat(stat_name, stat_file, pat.source, p);

fprintf('running %s on ''%s'' pattern...\n', func2str(f_stat), pat.name)

% load the pattern
pattern = get_mat(pat);
[n_events, n_chans, n_samps, n_freqs] = size(pattern);

n_out = length(f_outputs);

% initialize the outputs
output = cell(1, n_out);
for i = 1:n_out
  output{i} = cell(1, n_chans, n_samps, n_freqs);
end

p_sig = single(zeros(n_chans, n_samps, n_freqs));
p_boot = single(zeros(n_perm, n_chans, n_samps, n_freqs));

n_tests = n_chans * n_samps * n_freqs;
n = 0;
out = cell(1, n_out);
step = floor(n_tests / 1000);

if paired
  % PAIRED  
  for i = 1:n_chans
    for j = 1:n_samps
      for k = 1:n_freqs
        if mod(n, step) == 0 && n ~= 0
          fprintf('.')
        end
        
        % get this [1 x events] vector of data
        x = double(squeeze(pattern(:,i,j,k)));
        
        if all (isnan(x))
          % pattern is all NaNs; can't calculate any stat
          for o = 1:n_out
            output{o}{:,i,j,k} = NaN;
          end
          n = n + 1;
          continue
        end
        
        % run the function
        x_in = x(group(:) == 1);
        
        [out{:}] = f_stat(x_in, f_inputs{:});
          
        for o = 1:n_out
          output{o}{:,i,j,k} = out{o};
        end
        
        n = n + 1;
      end
    end
  end

else  
  % NOT PAIRED
  for i = 1:n_chans
    for j = 1:n_samps
      for k = 1:n_freqs
        if mod(n, step) == 0 && n ~= 0
          fprintf('.')
        end
        
        % get this [1 x events] vector of data
        x = double(squeeze(pattern(:,i,j,k)));
        
        if all (isnan(x))
          % pattern is all NaNs; can't calculate any stat
          for o = 1:n_out
            output{o}{:,i,j,k} = NaN;
          end
          n = n + 1;
          continue
        end
        
        % run the function
        x_in1 = x(group == 1);
        x_in2 = x(group == 2);
        x_in1 = x_in1(~isnan(x_in1));
        x_in2 = x_in2(~isnan(x_in2));
        
        %if all(isnan(x_in1)) | all(isnan(x_in2))
        if isempty(x_in1) | isempty(x_in2)
	  for o = 1:n_out
	    output{o}{:,i,j,k} = NaN;
          end
          n = n  + 1;
          continue
        end

        [out{:}] = f_stat(x_in1, x_in2, f_inputs{:});
        
        for o = 1:n_out
          output{o}{:,i,j,k} = out{o};
        end
        
        n = n + 1;
      end
    end
  end

end

% p-val for test
p_sig = permute(cell2num(output{p_out}), [2 3 4 1]);

fprintf('\n')

% PERMUTATION

fprintf('Iterations(%d): ', n_perm);

if paired
  % paired data shuffles is just a random switch of sign
  shuffles = [ones(1, fix(n_perm/2)) -ones(1, fix(n_perm/2))];
  ind = randperm2(size(x,1), n_perm);
  shuffles = shuffles(ind)';

  for s = 1:n_perm
    if mod(s, 50) == 1
      fprintf('%d ',s)
    end
    
    tmp_shuff = shuffles(s,:)';
    
    for i = 1:n_chans
      for j = 1:n_samps
        for k = 1:n_freqs
          
          % get this [1 x events] vector of data
          x = double(squeeze(pattern(:,i,j,k)));
          
          if all (isnan(x))
            % pattern is all NaNs; can't calculate any stat
            for o = 1:n_out
              output{o}{s,i,j,k} = NaN;
            end
            n = n + 1;
            continue
          end
          
          % run the function
          x = x.*tmp_shuff;
          x_in = x(group(:) == 1);
          
          [out{:}] = f_stat(x_in, f_inputs{:});
          
          for o = 1:n_out
            output{o}{s,i,j,k} = out{o};
          end
          
          n = n + 1;
        end
      end
    end
  end
    
else
  % not paired shuffles
  shuffles = randperm2(n_perm, size(x,1));
  
  for s = 1:n_perm
    tmp_shuffle = shuffles(s,:);
    
    for i = 1:n_chans
      for j = 1:n_samps
        for k = 1:n_freqs
          if mod(n, step) == 0 && n ~= 0
            fprintf('.')
          end
          
          % get this [1 x events] vector of data
          x = double(squeeze(pattern(:,i,j,k)));

          if all (isnan(x))
            % pattern is all NaNs; can't calculate any stat
            for o = 1:n_out
              output{o}{s,i,j,k} = NaN;
            end
            n = n + 1;
            continue
          end
          
          % run the function
          tmp_group = group(tmp_shuffle);
          x_in1 = x(tmp_group == 1);
          x_in2 = x(tmp_group == 2);
          x_in1 = x_in1(~isnan(x_in1));
          x_in2 = x_in2(~isnan(x_in2));
          
          %if all(isnan(x_in1)) | all(isnan(x_in2))
	  if isempty(x_in1) | isempty(x_in2)
            for o = 1:n_out
                output{o}{s,i,j,k} = NaN;
            end
            n = n  + 1;
            continue
          end
          
          [out{:}] = f_stat(x_in1, x_in2, f_inputs{:});
          
          for o = 1:n_out
            output{o}{s,i,j,k} = out{o};
          end
          
          n = n + 1;
        end
      end
    end
  end
      
end

% p-vals for bootstrap
p_boot = cell2num(output{p_out});

fprintf('\n\n')

% save the results
save(stat.file, 'p_sig', 'p_boot', 'shuffles');
pat = setobj(pat, 'stat', stat);



