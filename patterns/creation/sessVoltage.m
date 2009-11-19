function pattern = sessVoltage(pat,events,base_events,bins)
%SESSVOLTAGE   Create a voltage pattern for one session.
%   PATTERN = SESSVOLTAGE(PAT,BINS,EVENTS,BASE_EVENTS)
%
%   Params:
%     'relativeMS'
%     'baseOffsetMS'
%     'baseDurationMS'
%     'filttype'
%     'filtfreq'
%     'filtorder'
%     'bufferMS'
%     'kthresh'
%     'ztransform'
%
%   See also create_pattern, sessPower.
%

% default parameters
params = structDefaults(pat.params, ...
                        'evname', 'events',          ...
                        'replace_eegfile', {},       ...
                        'eventFilter',     '',       ...
                        'kthresh',         5,        ...
                        'chanFilter',      '',       ...
                        'resampledRate',   500,      ...
                        'offsetMS',        -200,     ...
                        'durationMS',      2200,     ...
                        'relativeMS',      [-200 0], ...
                        'filttype',        'stop',   ...
                        'filtfreq',        [58 62],  ...
                        'filtorder',       4,        ...
                        'bufferMS',        1000,     ...
                        'ztransform',      false,    ...
                        'baseOffsetMS',    -200,     ...
                        'baseDurationMS',  200,      ...
                        'overwrite',       false,    ...
                        'updateOnly',      false);
if ~isfield(params, 'baseEventFilter')
  params.baseEventFilter = params.eventFilter;
end
if ~isfield(params, 'baseRelativeMS')
  params.baseRelativeMS = params.relativeMS;
end

fprintf('Parameters are:\n\n')
disp(params);

%{
% get time bins in MS for each element of time dim for later artifact marking
timebins = make_bins(1000/params.resampledRate,params.offsetMS,params.offsetMS+params.durationMS);
%}

% initialize the pattern for this session
pattern = NaN(length(events), length(params.channels), length(pat.dim.time));

% load bad channel info for these events
%if params.excludeBadChans
%  [bad_chans, event_ind] = get_bad_chans({events.eegfile});
%end

fprintf('Channels: ')
for c=1:length(params.channels)
  fprintf('%d ', params.channels(c));

  % get baseline stats for this channel, sess
  if params.ztransform
    base_eeg = gete_ms(params.channels(c), ...
                       base_events, ...
                       params.baseDurationMS, ...
                       params.baseOffsetMS, ...
                       params.bufferMS, ... 
                       params.filtfreq, ...
                       params.filttype, ...
                       params.filtorder, ...
                       params.resampledRate, ...
                       params.baseRelativeMS);

    %{
    if ~isempty(params.kthresh)
      k = kurtosis(base_eeg,1,2);
      base_eeg = base_eeg(k<=params.kthresh,:);
    end
    %}

    % new way: get mean and std dev across events for each sample,
    % then average across samples
    base_mean = nanmean(nanmean(base_eeg,1));
    base_std = nanmean(std(base_eeg,1));
  end

  % get power, z-transform, average each time bin
  for e=1:length(events)
    this_eeg = squeeze(gete_ms(params.channels(c), ...
                               events(e), ...
                               params.durationMS, ...
                               params.offsetMS, ...
                               params.bufferMS, ...
                               params.filtfreq, ...
                               params.filttype, ...
                               params.filtorder, ...
                               params.resampledRate, ...
                               params.relativeMS));

    %{
    % check kurtosis for this event, add info to boolean mask for later
    if ~isempty(params.kthresh)
      k = kurtosis(this_eeg);
      if k>params.kthresh
        this_eeg(:) = NaN;
      end
    end
    %}

    % normalize across sessions
    if params.ztransform
      this_eeg = (this_eeg - base_mean)/base_std;
    end

    if ~isempty(params.artWindow)
      warning('artWindow option has been removed.')
    end
    
    %{    
    if params.excludeBadChans
      % remove bad channels
      isbad = mark_bad_chans(params.channels(c), bad_chans, event_ind(e));
      if isbad
        this_eeg(:) = NaN;
      end
    end
    %}
    
    % add this event/channel to the pattern
    pattern(e,c,:) = patMeans(this_eeg(:), bins(3));
    
  end % events

end % channel

% time already binned, events will be binned later
bins([1 3]) = {[]};

% bin channels
pattern = patMeans(pattern, bins);
