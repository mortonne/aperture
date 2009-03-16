function pattern = sessVoltage(pat,bins,events,base_events)
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
%     'artWindow'
%
%   See also create_pattern, sessPower.
%

% set defaults for pattern creation
params = structDefaults(pat.params, ...
                        'relativeMS',     [],      ...
                        'baseOffsetMS',   -200,    ...
                        'baseDurationMS', 100,     ...
                        'filttype',       'stop',  ...
                        'filtfreq',       [58 62], ...
                        'filtorder',      4,       ...
                        'bufferMS',       1000,    ...
                        'kthresh',        5,       ...
                        'ztransform',     1,       ...
                        'artWindow',      [-Inf Inf]);

if ~isfield(params,'baseRelativeMS')
  params.baseRelativeMS = params.relativeMS;
end

% get time bins in MS for each element of time dim for later artifact marking
timebins = make_bins(1000/params.resampledRate,params.offsetMS,params.offsetMS+params.durationMS);

% initialize the pattern for this session
pattern = NaN(length(events), length(params.channels), length(pat.dim.time));

% load bad channel info for these events
if params.excludeBadChans
  [bad_chans, event_ind] = get_bad_chans({events.eegfile});
end

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

		if ~isempty(params.kthresh)
			k = kurtosis(base_eeg,1,2);
			base_eeg = base_eeg(k<=params.kthresh,:);
		end

		%{
		% old way:
		% if multiple samples given, use the first
		base_eeg_vec = base_eeg(:,1);
		base_mean = nanmean(base_eeg_vec);
		base_std = nanstd(base_eeg_vec);
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

		% check kurtosis for this event, add info to boolean mask for later
		if ~isempty(params.kthresh)
			k = kurtosis(this_eeg);
			if k>params.kthresh
			  this_eeg(:) = NaN;
		  end
		end

		% normalize across sessions
		if params.ztransform
			this_eeg = (this_eeg - base_mean)/base_std;
		end
		
		if ~isempty(params.artWindow)
		  % remove blink artifacts
		  art = markArtifacts(events(e), timebins, params.artWindow);
		  this_eeg(art) = NaN;
	  end
		
		if params.excludeBadChans
		  % remove bad channels
		  isbad = mark_bad_chans(params.channels(c), bad_chans, event_ind(e));
		  if isbad
		    this_eeg(:) = NaN;
	    end
	  end
		
		% add this event/channel to the pattern
		pattern(e,c,:) = patMeans(this_eeg(:), bins(3));
		
	end % events

end % channel

% time already binned, events will be binned later
bins([1 3]) = {[]};

% bin channels
pattern = patMeans(pattern, bins);
