function pattern = sessPower(pat, events, base_events)

for c=1:length(pat.dim.chan)
	fprintf('%d.', pat.dim.chan(c).number);

	% if z-transforming, get baseline stats for this sess, channel
	if params.ztransform
		base_pow = getphasepow(pat.dim.chan(c).number, base_events, ...
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

		[this_pow] = getphasepow(chan(c).number, events(e), ...
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

		pattern(e,c,:,:) = this_pow;
	end
end