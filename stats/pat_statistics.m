function pat = pat_statistics(pat,event_bins,fcn_handle,fcn_inputs,stat_name,res_dir)
%PAT_STATISTICS   Run a statistical test on a pattern.
%
%  pat = pat_statistics(pat, event_bins, fcn_handle, fcn_inputs, stat_name, res_dir)
%
%  Use this function to run a test of significance on a pattern. You specify the
%  factors of the test in reference to the events structure corresponding to the
%  pat. The statistical test can be run by any function with a standard signature
%  outlined below.
%
%  INPUTS:
%         pat:  a pat object.
%
%  event_bins:  cell array where each cell specifies one factor to create from
%               each pat's event structure. See make_event_bins for options.
%
%  fcn_handle:  handle to a function that runs a statistical test of the form:
%                [p, statistic] = fcn_handle(chan_vec, group, ...)
%                INPUTS:
%                  chan_vec:  vector of data for one channel concatenated across 
%                             every pattern in pats.
%
%                     group:  cell array of labels with one cell per factor; each
%                             cell can contain an array or a cell array of strings.
%                             group{1} has a unique label for each pattern.
%
%                OUTPUTS:
%                         p:  scalar p-value of the significance test.
%
%                 statistic:  scalar containing the statistic (e.g. t or F) from
%                             which the p-value is derived.
%               Default fcn_handle is @run_sig_test, a which runs a
%               number of common significance tests with standard I/O.
%               
%  fcn_inputs:  cell array of additional inputs to fcn_handle.
%
%   stat_name:  string identifier for the statistic.
%
%     res_dir:  path to directory to save results; if not specified, the pattern's
%               default stats directory is used.
%
%  OUTPUTS:
%        stat:  stat object.
%
%  EXAMPLES:
%   % test for a significant subsequent memory effect
%   pat = pat_statistics(pat, {'recalled'}, @run_sig_test, {'anovan'});

% input checks
if ~exist('pat','var')
  error('You must pass a pat object.')
elseif ~exist('event_bins','var')
  error('You must pass a cell array of event bins.')
elseif ~exist('fcn_handle','var')
  fcn_handle = @run_sig_test;
end
if ~exist('fcn_inputs','var')
  fcn_inputs = {};
end
if ~exist('stat_name','var')
  stat_name = 'stat';
end
if ~exist('res_dir','var')
  res_dir = get_pat_dir(pat, 'stats');
elseif ~exist(res_dir,'dir')
  mkdir(res_dir);
end

fprintf('creating regressors...')
nfact = length(event_bins);
group = cell(1,nfact);

% load the events for this pattern
events = load_events(pat.dim.ev);

% make the regressors
for j=1:length(event_bins)
  group{j} = [group{j}; make_event_bins(events, event_bins{j})'];
end

% set the path to the MAT-file that will hold the results
filename = sprintf('%s_%s.mat', pat.name, stat_name);
stat_file = fullfile(res_dir, filename);

% initialize the stat object
stat = init_stat(stat_name, stat_file, pat.source, struct('event_bins',event_bins));

fprintf('running %s on %s...\n', func2str(fcn_handle), pat.name)

% set the size of the output variables
psize = patsize(pat.dim);
p = NaN(nfact,psize(2),psize(3),psize(4));
statistic = NaN(nfact,psize(2),psize(3),psize(4));

if ~isfield(pat.dim,'splitdim') || isempty(pat.dim.splitdim) || pat.dim.splitdim~=2
  % load the whole pattern
  full_pattern = load_pattern(pat);
end

fprintf('channel: ');
step = floor(psize(3)/4);
for c=1:psize(2)
  fprintf('%s', pat.dim.chan(c).label);
  
  if exist('full_pattern','var')
    % grab this slice
    pattern = full_pattern(:,c,:,:);
  else
    % nothing loaded yet; load just this channel
    pattern = load_pattern(pat,struct('patnum',c));
  end

  % run the statistic
  for t=1:size(pattern,3)
    if t~=size(pattern,3) && ~mod(t,step)
      fprintf('.')
    end
    for f=1:size(pattern,4)
      X = squeeze(pattern(:,1,t,f));
      [samp_p, samp_statistic] = fcn_handle(X, group, fcn_inputs{:});

      % check if we can determine the sign of the effect
      if length(group)==1
        reg = group{1}(~isnan(group{1}));
        vals = unique(reg);
        if length(vals)==2
          samp_p = samp_p*sign(nanmean(X(reg==vals(2))) - nanmean(X(reg==vals(1))));
        end
      end
      
      % add to the larger matrices
      p(:,c,t,f) = samp_p;
      statistic(:,c,t,f) = samp_statistic;
    end
  end
end
fprintf('\n')

if all(isnan(p(:)))
  error('Problem with sig test; p values are all NaNs.')
end

save(stat.file, 'p', 'statistic');
pat = setobj(pat, 'stat', stat);
