function pat = modify_pattern(pat, params, pat_name, res_dir)
%MODIFY_PATTERN   Modify an existing pattern.
%
%  pat = modify_pattern(pat, params, pat_name, res_dir)
%
%  Use this function to modify existing patterns. You can either save the
%  new pattern under a different name and/or file, or overwrite the old
%  one.
%
%  Operations are run in this order: 1) filtering, 2) binning, 3) principle
%  components analysis, 4) saving out in slices
%
%  INPUTS:
%       pat:  a pattern object.
%    params:  a structure specifying options for modifying the pattern.
%             See below.
%  pat_name:  string identifier for the new pattern. If this is the same
%             as pat.name, or if pat_name is not specified, the old
%             pattern will be replaced.
%   res_dir:  directory where the new pattern will be saved.
%
%  OUTPUTS:
%       pat:  a modified pattern object, named pat_name.
%
%  PARAMS:
%  Filtering
%   eventFilter - input to filterStruct; used to filter the events dimension
%   chanFilter  - filter for the channels dimension
%   chan_filter - filter that uses filter_struct instead of filterStruct
%   timeFilter  - filter for the time dimension
%   freqFilter  - filter for the frequency dimension
%
%  Artifact Rejection
%   excludeBadChans - if true, channels whose numbers are listed in
%                     fileparts(events.eegfile)/bad_chan.txt
%                     will be excluded for the relevant events
%   blinkthresh     - events where fast-slow running average of the difference
%                     between the EOG channels crosses this threshold are
%                     excluded (see find_eog_artifacts).
%   eog_channels    - channel number or pair of channels to use in blink
%                     detection
%   absThresh       - if any value in an event crosses this this threshold
%                     (either positive or negative), the event will be
%                     excluded for that channel
%
%  Binning
%   eventbins      - input to make_event_bins (for backwards compatibility,
%                    field can also be named "field".)
%   eventbinlabels - cell array of strings, with one cell per bin. Gives
%                    a label for each event bin, which appears in the
%                    'label' field of the modified events structure
%   chanbins       - 
%   chanbinlabels  - cell array of strings
%   MSbins         - [N bins X 2] array, where MSbins(Y,1) gives the start
%                    of bin Y in milliseconds, and MSbins(Y,2) gives the
%                    end of the bin
%   MSbinlabels    - cell array of strings
%   freqbins       - bins in Hz for the frequency dimension, specified in 
%                    the same format as MS bins
%   freqbinlabels  - cell array of string labels
%
%  PCA
%   nComp - number of principal components to extract
%
%  Z-Transform
%   ztrans           - if true, z-transform within each channel and 
%                      frequency
%   ztrans_eventbins - optional; specifies event bins to z-transform
%                      within separately
%
%  Slicing
%   splitDim - dimension along which to split the pattern into slices;
%              the pattern will be saved with one file per slice
%
%  EXAMPLE:
%   % calculate averages for recalled and not recalled events
%   params.field = 'recalled';
%   pat = getobj(subj, 'pat', 'voltage');
%
%   % get the average for each unique value of the 'recalled' field
%   % of events, and overwrite the old pattern
%   pat = modify_pattern(pat, params);

% input checks
if ~exist('pat','var')
  error('You must pass a pattern object.')
elseif ~isstruct(pat)
  error('pat must be a structure.')
elseif isempty(pat)
  error('The input pat object is empty.')
end
if ~isfield(pat, 'modified')
  pat.modified = false;
end
if ~exist('params','var')
  params = struct;
end
if ~exist('pat_name','var') | isempty(pat_name)
  % default to overwriting the existing pattern
  pat_name = pat.name;
end
if ~exist('res_dir','var') || isempty(res_dir)
  pat_dir = get_pat_dir(pat);
  res_dir = fullfile(fileparts(pat_dir), pat_name);
end

% default parameters
params = structDefaults(params, ...
                        'nComp',           [], ...
                        'badChanFiles',    {},  ...
                        'blinkthresh',     [], ...
                        'eog_channels',    {[25 127], [8 126]}, ...
                        'eog_buffer',      200, ...
                        'blinkopt',        [.5, .5, .975, .025], ...
                        'absThresh',       [], ...
                        'kthresh',         [],  ...
                        'min_samp',        [], ...
                        'ztrans',          0,  ...
                        'ztrans_eventbins', 'overall', ...
                        'overwrite',       0,  ...
                        'lock',            0,  ...
                        'splitDim',        [], ...
                        'savePat',         1);

fprintf('modifying pattern %s...', pat.name)

% if the pat_name is different, save the pattern to a new file
if ~strcmp(pat.name, pat_name)
  saveas = true;
  pat.name = pat_name;
  pat_dir = fullfile(res_dir, 'patterns');
  pat_file = fullfile(pat_dir, ...
                      objfilename('pattern', pat.name, pat.source));
  if ~exist(pat_dir,'dir')
    mkdir(pat_dir);
  end
else
  saveas = false;
  pat_file = pat.file;
end

% if the file exists and we're not overwriting, return
pat_loc = get_obj_loc(pat);
if strcmp(pat_loc, 'hd') && ~params.overwrite && exist(pat_file,'file')
  fprintf('pattern %s exists. Skipping...\n', pat.name)
  return
end

% get the pattern and corresponding events
pat = move_obj_to_workspace(pat);
ev_loc = get_obj_loc(ev);
pat.dim.ev = move_obj_to_workspace(pat.dim.ev);

% update the pattern object
pat.file = pat_file;
pat.params = combineStructs(params, pat.params);

% make requested modifications
pat = pattern_ops(pat, params);

% if event have been modified, change the filepath. We don't want to
% overwrite any source events that might be used for other patterns, 
% etc., so we'll change the path even if we are using the same 
% pat_name as before.
if pat.dim.ev.modified
  events_dir = get_pat_dir(pat, 'events');
  pat.dim.ev.file = fullfile(events_dir, objfilename('events', ...
                                                    pat.name, pat.source));
  % if the original events were saved to disk, save the new events to
  % disk as well
  if strcmp(ev_loc, 'hd')
    ev = move_obj_to_hd(ev);
  end
end

% save the pattern where we found it
if strcmp(pat_loc, 'hd')
  pat = move_obj_to_hd(pat);
  
  if ~isempty(params.splitDim)
    pat = split_pattern(pat, params.splitDim);
  end
  
  if saveas
    fprintf('saved as "%s".\n', pat.name)
  else
    fprintf('saved.\n')
  end
else
  % already should be in pat.mat
  pat.modified = true;
  pat.dim.splitdim = [];
end


function pat = pattern_ops(pat, params)
  % apply filtering
  [pat, inds] = patFilt(pat, params);
  pat.mat = pat.mat(inds{:});
  pat_size = patsize(pat.dim);

  % ARTIFACT FILTERS
  % exclude bad channel-sessions
  if ~isempty(params.badChanFiles)
    % load bad channel info
    [bad_chans, event_ind] = get_bad_chans({events.eegfile}, params.badChanFiles);

    % get current channel numbers
    chan_numbers = [pat.dim.chan.number];

    % combine channel and event info to make a bad channels logical array
    isbad = mark_bad_chans(chan_numbers, bad_chans, event_ind);

    % expand isbad to the same dimensions as pattern
    isbad = repmat(isbad, [1 1 pat_size(3:end)]);

    % mark bad parts of the pattern
    pat.mat(isbad) = NaN;
  end

  % reject time bins with blink artifacts
  if ~isempty(params.blinkthresh)
    % set range of samples to search
    first = pat.dim.time(1).MSvals(1);
    last = pat.dim.time(end).MSvals(end);
    offsetMS = first;
    durationMS = last - first;
    
    % events X time
    params.resampledrate = get_pat_samplerate(pat);
    bad_samples = false(patsize(pat.dim,1), patsize(pat.dim,3));
    for i=1:length(params.eog_channels)
      artifacts = find_eog_artifacts(pat.dim.ev.mat, ...
                                     params.eog_channels{i}, ...
                                     offsetMS, ...
                                     durationMS, ...
                                     params);
      bad_samples = bad_samples | [artifacts artifacts(:,end)];
    end
    %bad_samples(any(bad_samples,2),:) = true;
    
    bad = repmat(bad_samples, [1 1 pat_size(2) pat_size(4)]);
    bad = permute(bad, [1 3 2 4]);
    pat.mat(bad) = NaN;
    fprintf('Threw out %d samples out of %d with eye artifacts.\n', ...
            nnz(bad_samples), numel(bad_samples))
    %pat.mat(bad_events,:,:,:) = NaN;
    %fprintf('Threw out %d events out of %d with EOG artifacts.\n', ...
    %        length(find(bad_events)), length(bad_events))
  end

  mask = false(pat_size);
  
  % reject event-channels that have any values above a given threshold
  if params.absThresh
    mask = mask | reject_threshold(pat.mat, params.absThresh);
  end

  % reject event-channel-freqs with high kurtosis
  if params.kthresh
    mask = mask | reject_kurtosis(pat.mat, params.kthresh);
  end
  pat.mat(mask) = NaN;

  % Z-TRANSFORM
  if params.ztrans
    % divide events to take z-transform within
    labels = make_event_bins(pat.dim.ev.mat, params.ztrans_eventbins);
    uniq_labels = unique(labels);
    for label=uniq_labels
      ind = label==labels;
      x = pat.mat(ind,:,:,:);
      pat.mat(ind,:,:,:) = ztrans_pattern(x);
    end
  end

  % BINNING
  [pat, bins] = patBins(pat, params);
  pat.mat = patMeans(pat.mat, bins, params.min_samp);

  % PCA
  if ~isempty(params.nComp)
    % run PCA on the pattern
    [pat, coeff] = patPCA(pat, params);
    filename = objfilename('coeff', pat.name, pat.source);
    pat.dim.coeff = fullfile(get_pat_dir(pat, 'patterns'), filename);
    save(pat.dim.coeff, 'coeff');
  end
%endfunction
