function stat = mult_pat_sig_test(pats,event_bins,fcn_handle,fcn_inputs,stat_name,res_dir)
%MULT_PAT_SIG_TEST   Test for significance across multiple patterns.
%
%  stat = mult_pat_sig_test(pats, event_bins, fcn_handle, fcn_inputs, stat_name, res_dir)
%
%  Use this function to run a test of significance across subjects. You specify the
%  factors of the test in reference to the events structure corresponding to each
%  pat. The statistical test can be run by any function with a standard signature
%  outlined below.
%
%  INPUTS:
%        pats:  vector of pat objects.
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
%               fullfile(fileparts(fileparts(pats(1).file)),'stats')
%
%  OUTPUTS:
%        stat:  stat object.
%
%  EXAMPLES:
%   % test for a significant subsequent memory effect across subjects
%   pats = ;
%   stat = mult_pat_sig_test(pats, {'recalled'}, @RMAOV1, {}, 'sme')

% input checks
if ~exist('pats','var')
  error('You must pass a vector of pat objects.')
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
  % get the path to the first pattern's file
  if iscell(pats(1).file)
    pat1_file = pats(1).file{1};
    else
    pat1_file = pats(1).file;
  end
  
  % set the default results directory
  res_dir = fullfile(fileparts(fileparts(pat1_file)), 'stats');
end
if ~exist(res_dir,'dir')
  mkdir(res_dir);
end

fprintf('creating regressors...')
group = cell(1,length(event_bins));
for pat=pats
  % load the events for this pattern
  events = loadEvents(pat.dim.ev.file);
  
  % make the regressors
  for i=1:length(event_bins)
    group{i} = [group{i}; binEventsField(events, event_bins)'];
  end
  %group{end} = [group{end}; ones(subjpat(s).dim.ev.len,1)*s];
end

% set the path to the MAT-file that will hold the results
filename = sprintf('%s_%s.mat', pat.name, stat_name);
stat_file = fullfile(res_dir, filename);

% initialize the stat object
stat = init_stat(stat_name, stat_file, 'multiple', struct('event_bins',event_bins));

fprintf('running %s...\n', func2str(fcn_handle))

% set the size of the output variables
psize = patsize(pat.dim);
nfact = length(event_bins);
p = NaN(nfact,psize(2),psize(3),psize(4));
statistic = NaN(nfact,psize(2),psize(3),psize(4));

fprintf('Channel: ');
for c=1:psize(2)
  fprintf('%s', pat.dim.chan(c).label);
  
  % concatenate subjects
  pattern = [];
  for pat=pats
    % load the pattern for this channel
    if iscell(pat.file)
      if length(pat.file)~=psize(2)
        error('pattern %s saved in slices over a dimension other than channels.', pat.name)
      end
      
      % saved in slices; we can load just this channel
      chan_pat = load_pattern(pat, struct('patnum',c));
      pattern = cat(1, pattern, chan_pat);
      
      else
      % we need to load the whole pattern
      full_pattern = load_pattern(pat);
      pattern = cat(1, pattern, full_pattern(:,c,:,:));
    end
  end

  % run the statistic
  for t=1:size(pattern,3)
    if ~mod(t,floor(size(pattern,3)/4))
      fprintf('.')
    end
    for f=1:size(pattern,4)
      [p(:,c,t,f), statistic(:,c,t,f)] = fcn_handle(squeeze(pattern(:,1,t,f)), group, fcn_inputs{:});
      %p(:,c,t,f) = run_sig_test(squeeze(pattern(:,:,t,f)),group,params.test,params.testinput{:});
    end
  end
end
fprintf('\n')

if all(isnan(p(:)))
  error('Problem with sig test; p values are all NaNs.')
end

save(stat.file, 'p', 'statistic');
