function pat = modify_pattern(pat, params, pat_name, res_dir)
%MODIFY_PATTERN   Modify an existing pattern.
%
%  pat = modify_pattern(pat, params, pat_name, res_dir)
%
%  Use this function to modify existing patterns. You can either save
%  the new pattern under a different name, or overwrite the old one.  To
%  save under a new name, set pat_name to the new name.  The output pat
%  object will have that name.  
%
%  By default, modified patterns will be saved in a subdirectory of the
%  parent of the main directory of the input pattern.  The new pattern's
%  main directory will be named pat_name.
%
%  If input pat is saved to disk, the new pattern will be saved in a
%  new file in [res_dir]/patterns.  If events are modified, and they are
%  saved on disk, the modified events will be saved in
%  [res_dir]/events.  In case the events are used by other objects, they
%  will be saved to a new file even if pat_name doesn't change.
%
%  Operations are run in this order: 1) filtering, 2) binning,
%  3) principle components analysis, 4) saving out in slices.
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
%  All fields are optional.  Defaults are shown in parentheses.
%   overwrite - if true, existing patterns will be overwritten.  (false
%               if pattern is stored on disk, true if pattern is stored
%               in workspace or if save_mats is false)
%   save_mats - if true, and input mats are saved on disk, modified mats
%               will be saved to disk. If false, the modified mats will
%               be stored in the workspace, and can subsequently be
%               moved to disk using move_obj_to_hd. This option is
%               useful if you want to make a quick change without
%               modifying a saved pattern. (true)
%
%  Filtering
%   eventFilter - input to filterStruct; used to filter the events
%                 dimension
%   chanFilter  - filter for the channels dimension
%   chan_filter - filter that uses filter_struct instead of filterStruct
%   timeFilter  - filter for the time dimension
%   freqFilter  - filter for the frequency dimension
%
%  Artifact Rejection
%   excludeBadChans - if true, channels whose numbers are listed in
%                     fileparts(events.eegfile)/bad_chan.txt
%                     will be excluded for the relevant events
%   blinkthresh     - events where fast-slow running average of the
%                     difference between the EOG channels crosses this
%                     threshold are excluded (see find_eog_artifacts).
%   eog_channels    - channel number or pair of channels to use in blink
%                     detection
%   eog_buffer      - 
%   blinkopt        - 
%   absThresh       - if any value in an event crosses this this
%                     threshold (either positive or negative), the event
%                     will be excluded for that channel
%
%  Binning
%   eventbins      - input to make_event_bins (for backwards
%                    compatibility, field can also be named "field".)
%   eventbinlabels - cell array of strings, with one cell per bin. Gives
%                    a label for each event bin, which appears in the
%                    'label' field of the modified events structure
%   chanbins       - 
%   chanbinlabels  - cell array of strings
%   MSbins         - [N bins X 2] array, where MSbins(Y,1) gives the
%                    start of bin Y in milliseconds, and MSbins(Y,2)
%                    gives the end of the bin
%   MSbinlabels    - cell array of strings
%   freqbins       - bins in Hz for the frequency dimension, specified
%                    in the same format as MS bins
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
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must pass a pattern object.')
elseif isempty(pat)
  error('The input pat object is empty.')
end
if ~isfield(pat, 'modified')
  pat.modified = false;
end
if ~exist('params', 'var')
  params = struct;
end
if ~exist('pat_name', 'var') | isempty(pat_name)
  % default to overwriting the existing pattern
  pat_name = pat.name;
end
if ~exist('res_dir', 'var') || isempty(res_dir)
  % default to parallel directory to input pattern, named pat_name
  % if pat.file is a relative path, this may fail
  pat_dir = get_pat_dir(pat);
  res_dir = fullfile(fileparts(pat_dir), pat_name);
end

% get the location of the input pat; this will set the default of
% whether the new pattern is saved to workspace or hard drive
pat_loc = get_obj_loc(pat);
ev_loc = get_obj_loc(pat.dim.ev);

% set default for whether to overwrite existing pattern
if strcmp(pat_loc, 'ws') || (isfield(params, 'save_mats') && ~params.save_mats)
  defaults.overwrite = true;
else
  defaults.overwrite = false;
end

% set default params
defaults.save_mats = true;
defaults.eventFilter = '';
defaults.chanFilter = '';
defaults.chan_filter = '';
defaults.timeFilter = '';
defaults.freqFilter = '';
defaults.excludeBadChans = false;
defaults.badChanFiles = {};
defaults.blinkthresh = [];
defaults.eog_channels = {[25 127], [8 126]};
defaults.eog_buffer = 200;
defaults.blinkopt = [.5 .5 .975 .025];
defaults.absThresh = [];
defaults.kthresh = [];
defaults.eventbins = [];
defaults.eventbinlabels = {};
defaults.chanbins = [];
defaults.chanbinlabels = {};
defaults.MSbins = [];
defaults.MSbinlabels = {};
defaults.freqbins = [];
defaults.freqbinlabels = {};
defaults.nComp = [];
defaults.min_samp = [];
defaults.ztrans = false;
defaults.ztrans_eventbins = 'overall';
defaults.splitDim = [];

% update the pattern's params
user_params = merge_structs(params, pat.params);
params = propval(params, defaults);
user_params = merge_structs(user_params, params);

fprintf('modifying pattern %s...', pat.name)

% before modifying the pat object, make sure files, etc. are OK
if ~strcmp(pat.name, pat_name)
  saveas = true;
  
  % use "patterns" subdirectory of res_dir
  pat_dir = fullfile(res_dir, 'patterns');
  pat_file = fullfile(pat_dir, ...
                      objfilename('pattern', pat_name, pat.source));
  
  % check to see if there's already a pattern there that we don't want
  % to overwrite
  if strcmp(pat_loc, 'hd') && ~params.overwrite && exist(pat_file, 'file')
    fprintf('pattern "%s" exists in new file. Skipping...\n', pat_name)
    return
  end
  
  % make sure the parent directory exists
  if ~exist(pat_dir, 'dir')
    mkdir(pat_dir);
  end
else
  saveas = false;
  
  % should we overwrite this pattern?  Regardless of hd or ws
  if ~params.overwrite && exist_mat(pat)
    fprintf('pattern "%s" exists. Skipping...\n', pat.name)
    return
  end
end

% for ease of passing things around, temporarily move the mats to the
% workspace, if they aren't already
pat = move_obj_to_workspace(pat);
pat.dim.ev = move_obj_to_workspace(pat.dim.ev);

% update params
pat.params = combineStructs(user_params, pat.params);

% make requested modifications; pattern and events may be modified in
% the workspace
pat = pattern_ops(pat, params);

if saveas
  % change the name and point to the new file
  pat.name = pat_name;
  pat.file = pat_file;
end

% if event have been modified, change the filepath. We don't want to
% overwrite any source events that might be used for other patterns, 
% etc., so we'll change the path even if we are using the same 
% pat_name as before. Even if we're not saving, we'll change the file
% in case events are saved to disk later.
if pat.dim.ev.modified
  events_dir = get_pat_dir(pat, 'events');
  pat.dim.ev.file = fullfile(events_dir, objfilename('events', ...
                                                    pat.name, pat.source));
end

% either move unmodified events back to disk, or save modified events
% to their new file
if params.save_mats && strcmp(ev_loc, 'hd')
  pat.dim.ev = move_obj_to_hd(pat.dim.ev);
end

% save the pattern where we found it
if params.save_mats && strcmp(pat_loc, 'hd')
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
  pat.dim.splitdim = [];
  
  if saveas
    fprintf('returning as "%s".\n', pat.name)
  else
    fprintf('updated.\n')
  end
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
  
  %i'm using pat.mat as a temporary storage for a cluster mask,
  %which is a logical, but pattern_ops doesn't play nice with
  %logicals, so this hack makes it a numeric array...
  %ZACH HACK
  pat.mat = +pat.mat;
  %END ZACH HACK
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
  
  pat.modified = true;
%endfunction
