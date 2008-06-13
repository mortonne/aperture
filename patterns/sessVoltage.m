function pattern = sessVoltage(pat,events,base_events,artifacts)

for c=1:length(chan)
	fprintf('%s.', chan(c).label);

	% get baseline stats for this channel, sess
	if params.ztransform
		base_eeg = gete_ms(chan(c).number, base_events, ...
		params.baseDurationMS, params.baseOffsetMS, params.bufferMS, ... 
		params.filtfreq, params.filttype, params.filtorder, ...
		params.resampledRate, params.relativeMS);

		if ~isempty(params.kthresh)
			k = kurtosis(base_eeg,1,2);
			base_eeg = base_eeg(k<=params.kthresh,:);
		end

		% if multiple samples given, use the first
		base_eeg_vec = base_eeg(:,1);
		base_mean = nanmean(base_eeg_vec);
		base_std = nanstd(base_eeg_vec);   
	end

	% get power, z-transform, average each time bin
	for e=1:length(sess_events)
		this_eeg = squeeze(gete_ms(chan(c).number, events(e), ...
		params.durationMS, params.offsetMS, params.bufferMS, ...
		params.filtfreq, params.filttype, params.filtorder, ...
		params.resampledRate, params.relativeMS));

		% check kurtosis for this event, add info to boolean mask for later
		if ~isempty(params.kthresh)
			k = kurtosis(this_eeg)
			this_eeg(k>params.kthresh) = NaN;
		end

		% normalize across sessions
		if params.ztransform
			this_eeg = (this_eeg - base_mean)/base_std;
		end

		% clip artifacts
		if exist('artifacts','var')
			this_eeg(squeeze(artifacts(e,:))) = NaN;
		end

		% add this event/channel to the pattern
		for t=1:length(patbins{3})
			pattern(e,c,t) = nanmean(this_eeg(bins{3}{t}));
		end
	end % events

end % channel
