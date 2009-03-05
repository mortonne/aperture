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
%               each pat's event structure. See binEventsField for options.
%
%  fcn_handle:  handle to a function that runs a statistical test of the form:
%               [p, statistic] = fcn_handle(chan_vec, group, ...)
%               INPUTS:
%                 chan_vec:  vector of data for one channel concatenated across 
%                            every pattern in pats.
%
%                    group:  cell array of labels with one cell per factor; each
%                            cell can contain an array or a cell array of strings.
%                            group{1} has a unique label for each pattern.
%
%               OUTPUTS:
%                        p:  scalar p-value of the significance test.
%
%                statistic:  scalar containing the statistic (e.g. t or F) from
%                            which the p-value is derived.
%               
%  fcn_inputs:  cell array of additional inputs to fcn_handle.
%
%   stat_name:  string identifier for the statistic.
%
%     res_dir:  path to directory to save results (default:
%               fullfile(fileparts(fileparts(pat.file)),'stats')
%
%  OUTPUTS:
%        stat:  stat object.
%
%  EXAMPLES:
%   % test for a significant subsequent memory effect
%   pat = mult_pat_sig_test(pat, {'recalled'}, @anovan, {}, 'sme')

% input checks
if ~exist('pat','var')
  error('You must pass a pat object.')
  elseif ~exist('event_bins','var')
  error('You must pass a cell array of event bins.')
  elseif ~exist('fcn_handle','var')
  error('You must pass a handle to a significance test function.')
end
if ~exist('fcn_inputs','var')
  fcn_inputs = {};
end
if ~exist('stat_name','var')
  stat_name = 'stat';
end
if ~exist('res_dir','var')
  % get the path to the pattern's file
  if iscell(pat.file)
    pat_file = pat.file{1};
    else
    pat_file = pat.file;
  end
  
  % set the default results directory
  res_dir = fullfile(fileparts(fileparts(pat_file)), 'stats');
end
if ~exist(res_dir,'dir')
  mkdir(res_dir);
end

fprintf('creating regressors...')
nfact = length(event_bins);
group = cell(1,nfact);

% load the events for this pattern
events = loadEvents(pat.dim.ev.file);
  
% make the regressors
for j=1:length(event_bins)
  group{j} = [group{j}; binEventsField(events, event_bins{j})'];
end

% set the path to the MAT-file that will hold the results
filename = sprintf('%s_%s.mat', pat.name, stat_name);
stat_file = fullfile(res_dir, filename);

% initialize the stat object
stat = init_stat(stat_name, stat_file, 'multiple', struct('event_bins',event_bins));

fprintf('running %s...\n', func2str(fcn_handle))

% set the size of the output variables
psize = patsize(pat.dim);
p = NaN(nfact,psize(2),psize(3),psize(4));
statistic = NaN(nfact,psize(2),psize(3),psize(4));

% load the pattern
pattern = load_pattern(pat);

fprintf('Channel: ');
for c=1:psize(2)
  fprintf('%s', pat.dim.chan(c).label);
  
  % run the statistic
  for t=1:size(pattern,3)
    if ~mod(t,floor(size(pattern,3)/4))
      fprintf('.')
    end
    for f=1:size(pattern,4)
      [p(:,c,t,f), statistic(:,c,t,f)] = fcn_handle(squeeze(pattern(:,c,t,f)), group, fcn_inputs{:});
    end
  end
end
fprintf('\n')

if all(isnan(p(:)))
  error('Problem with sig test; p values are all NaNs.')
end

save(stat.file, 'p', 'statistic');
pat = setobj(pat, 'stat', stat);
