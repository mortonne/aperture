function pattern = sessPower(pat,bins,events,base_events)
%SESSPOWER   Create a power pattern for one session.
%
%  pattern = sessPower(pat, bins, events, base_events)
%
%  Power is calculated using Morlet wavelets for all events in the event 
%  structure using getphasepow. The result is stored in a matrix called
%  a "pattern."
%
%  Power is calculated for one session at a time because there is assumed
%  to be variation in electrode position, impedance, etc. that changes
%  between sessions. This variation can be dealt with by z-transforming
%  within each session, channel, and frequency.
%
%  INPUTS:
%          pat:  structure that holds metadata for a pattern (see
%                create_pattern for details). The options in pat.params
%                affect how the pattern is created.
%
%         bins:  cell array with one cell for each dimension of pattern;
%                each cell should contain a cell array, and each cell
%                contains indices for one bin.
%
%       events:  an events structure. This should contain every event
%                you want power for.
%
%  base_events:  an events structure. These events are used to calculate
%                baseline power for z-transforming.
%
%  OUTPUTS:
%      pattern:  an [events X channel X time X frequency] matrix containing
%                power values.
%
%  pat.params can contain the following fields to specify options for creating
%  the pattern:
%
%  PARAMS:
%    baseOffsetMS:  Time from the beginning of each baseline event to
%                   calculate power.
%  baseDurationMS:  Duration of the baseline period for each baseline
%                   event (currently doesn't matter, since the first
%                   sample is used to calculate baseline stats).
%        filttype:  Type of filter to use (see buttfilt)
%        filtfreq:  Frequency range for filter (see buttfilt)
%       filtorder:  Order of filter (see buttfilt)
%        bufferMS:  Size of buffer to use when filtering (see buttfilt)
%           width:  Size of wavelets to use in power calculation
%                   (see getphasepow)
%         kthresh:  Kurtosis threshold: if kurtosis of the raw voltage 
%                   of any event exceeds this value, power for that event
%                   will be excluded (replaced with NaNs).
%      ztransform:  Logical specifying whether to z-transform the power
%    logtransform:  Logical specifying whether to log-transform the power
%       artWindow:  Two-element vector specifying what to exclude on events
%                   that contain a blink artifact:
%                     artWindow(1) - time in ms before the blink onset to begin
%                                    excluding
%                     artWindow(2) - time in ms after the blink onset to exclude
%                   Excluded time periods will be replaced with NaNs for that
%                   event for all channels.
%
%  See also create_pattern, sessVoltage.

% set defaults for pattern creation
params = structDefaults(pat.params, ...
                        'baseOffsetMS',    -200,     ...
                        'baseDurationMS',  100,      ...
                        'filttype',        'stop',   ...
                        'filtfreq',        [58 62],  ...
                        'filtorder',       4,        ...
                        'bufferMS',        1000,     ...
                        'width',           6,        ...
                        'kthresh',         5,        ...
                        'ztransform',      1,        ...
                        'logtransform',    0,        ...
                        'artWindow',       500);

% get the final sample rate
if ~isempty(params.downsample)
  final_rate = params.downsample;
  else
  final_rate = params.resampledRate;
end

% get time bins in MS for each element of time dim for later artifact marking
timebins = makeBins(1000/final_rate,params.offsetMS,params.offsetMS+params.durationMS);

% initialize the pattern for this session
pattern = NaN(length(events), length(params.channels), length(pat.dim.time), length(pat.dim.freq));

% load bad channel info for these events
[bad_chans, event_ind] = get_bad_chans({events.eegfile});

fprintf('Channels: ')
for c=1:length(params.channels)
	fprintf('%d ', params.channels(c));

	% if z-transforming, get baseline stats for this sess, channel
	if params.ztransform
		base_pow = getphasepow(params.channels(c), base_events, ...
		params.baseDurationMS, ...
		params.baseOffsetMS, params.bufferMS, ... 
		'freqs', params.freqs, ... 
		'filtfreq', params.filtfreq, ... 
		'filttype', params.filttype, ...
		'filtorder', params.filtorder, ... 
		'kthresh', params.kthresh, ...
		'width', params.width, ...
		'resampledRate', params.resampledRate, ...
		'downsample', params.downsample, ...				
		'powonly');

		% do log transform if desired
		if params.logtransform
			base_pow(base_pow<=0) = eps(0);
			base_pow = log10(base_pow);
		end

		for f=1:length(params.freqs)
			% if multiple samples given, use the first
			base_pow_vec = base_pow(:,f,1);

			% get separate baseline stats for each freq
			base_mean(f) = nanmean(base_pow_vec);
			base_std(f) = nanstd(base_pow_vec);
		end
	end % baseline

	% get power, z-transform, average each time bin
	for e=1:length(events)
		[this_pow] = getphasepow(params.channels(c), events(e), ...
		params.durationMS, ...
		params.offsetMS, params.bufferMS, ... 
		'freqs', params.freqs, ... 
		'filtfreq', params.filtfreq, ... 
		'filttype', params.filttype, ...
		'filtorder', params.filtorder, ... 
		'kthresh', params.kthresh, ...
		'width', params.width, ...
		'resampledRate', params.resampledRate, ...
		'downsample', params.downsample, ...
		'powonly');

		if isempty(this_pow)
			continue
		end

    if params.logtransform
      % if any values are exactly 0, make them eps
			this_pow(this_pow==0) = eps(0);
			
			% do the transform
			this_pow = log10(this_pow);
		end

		% make it time X frequency
		this_pow = shiftdim(squeeze(this_pow),1);

		if params.ztransform
      % z-transform
	    for f=1:length(params.freqs)
				this_pow(:,f) = (this_pow(:,f) - base_mean(f))/base_std(f);
			end
		end

    if ~isempty(params.artWindow)
      % remove blink artifacts
		  art = markArtifacts(events(e), timebins, params.artWindow);
		  this_pow(find(art),:) = NaN;
	  end

    if params.excludeBadChans
		  % remove bad channels
		  isbad = mark_bad_chans(params.channels(c), bad_chans, event_ind(e));
	    this_eeg(find(isbad),:) = NaN;
	  end

		% bin time and frequency, and add the power of this eventXchannel
		pattern(e,c,:,:) = patMeans(this_pow, bins(3:4));
	end % events
	
end % channels

% bin channels
bins([1 3:4]) = {[]};
pattern = patMeans(pattern, bins);
