function pattern = sessPower(pat,bins,events,base_events)

% set defaults for pattern creation
params = structDefaults(pat.params, 'baseOffsetMS', -200,  'baseDurationMS', 100,  'filttype', 'stop',  'filtfreq', [58 62],  'filtorder', 4,  'bufferMS', 1000,  'width', 6,  'kthresh', 5,  'ztransform', 1,  'logtransform', 0);

timebins = makeBins(1000/params.resampledRate,params.offsetMS,params.offsetMS+params.durationMS);

% initialize the pattern for this session
pattern = NaN(length(events), length(params.channels), length(pat.dim.time), length(pat.dim.freq));

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

		% make it time X frequency
		this_pow = shiftdim(squeeze(this_pow),1);

		for f=1:length(params.freqs)

			if params.ztransform
				if params.logtransform
					this_pow(this_pow<=0) = eps(0);
					this_pow = log10(this_pow);
				end

				% z-transform
				this_pow(:,f) = (this_pow(:,f) - base_mean(f))/base_std(f);
			end
		end

    if ~isempty(params.artWindow)
		  art = markArtifacts(events(e), timebins, params.artWindow);
		  this_pow(find(art),:) = NaN;
	  end

		% add the power of this eventXchannel
		pattern(e,c,:,:) = patMeans(this_pow, bins(3:4));
	end % events
	
end % channels

% bin channels
bins([1 3:4]) = {[]};
pattern = patMeans(pattern, bins);
