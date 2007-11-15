function pow_anova_scalp(eeg)
%
%POW_ANOVA_SCALP - calculates an n-way ANOVA across subjects
%
% FUNCTION: pow_anova_scalp(eeg)
%
% INPUT: eeg - struct created by running init_scalp; eeg.params
%        must contain a field 'field' that has the name of each
%        field in the events struct to be used as a regressor
% 
% OUTPUT: power values with significance, saved by channel in
%         'eeg.resDir/'
%


% set the defaults for params
eeg.params = structDefaults(eeg.params, 'width', 6,  'freqs', 2.^((8:48)/8),  'kthresh', 5,  'ztransform', 1);

params = eeg.params;
disp(params);

% convert MS values to samples
durationSamp = fix(params.durationMS*params.resampledRate./1000);
binSizeSamp = fix(params.binSizeMS*params.resampledRate./1000);
nBins = fix(durationSamp/binSizeSamp);

baseStartSamp = fix((params.relativeMS(1) - params.offsetMS).*params.resampledRate/1000) + 1;
baseEndSamp = fix((params.relativeMS(2) - params.offsetMS).*params.resampledRate/1000);
baseSamp = baseStartSamp:baseEndSamp;

binSamp(1,:) = [1:binSizeSamp];
for b=2:nBins
  binSamp(b,:) = binSamp(b-1,:) + binSizeSamp;
end

% get the labels for the anova, make the Data template
Temp.field = getStructField(params, 'field'); 

load(eeg.subj(1).sess(1).eventsFile);
events = filterStruct(events, params.eventFilter);
for f=1:length(params.field)
  Temp.field(f).p = NaN(length(params.freqs), nBins);
  labels = unique(getStructField(events, params.field(f).name));
  for l=1:length(labels)
    if iscell(labels(l))
      Temp.field(f).label(l).value = labels{l};
      eeg.params.field(f).label(l).value = labels{l};
    else
      Temp.field(f).label(l).value = labels(l);
      eeg.params.field(f).label(l).value = labels(l);
    end
    if params.field(f).plot
      Temp.field(f).label(l).pow = NaN(length(params.freqs), nBins);
    end
  end
end

if ~exist(fullfile(eeg.resDir, 'data'), 'dir')
  mkdir(fullfile(eeg.resDir, 'data'));
end

fprintf(['\nStarting Power ANOVA:\n']);

% step through channels
for c=1:length(eeg.chan)
  channel = eeg.chan(c).number;
    
  eeg.chan(c).anovaFile = fullfile(eeg.resDir, 'data', ['anova_chan' num2str(channel) '.mat']);
  % if this channel has been or is being processed, skip to the next
  if ~lockFile(eeg.chan(c).anovaFile)
    save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');
    continue
  end
  
  % initialize the struct that will hold data for this channel
  Data = Temp;
  
  fprintf('\n***Channel %d***', channel);   
  
  for f=1:length(params.freqs)
    freq = params.freqs(f);
    
    chan_pow = [];
    chan_events = [];
    fprintf('\nLoading power values (%.2fHz)...', freq);
    
    % get all sessions, so we can do the anova
    for s=1:length(eeg.subj)
      fprintf('%s', eeg.subj(s).id);
      
      for n=1:length(eeg.subj(s).sess)
	if ~ismember(channel, eeg.subj(s).sess(n).goodChans)
	  continue
	end
	fprintf('.');
	
	events = loadEvents(eeg.subj(s).sess(n).eventsFile, params.replace_eegFile);
	
	% get the desired events for this subj, this sess
	sess_events = filterStruct(events, params.eventFilter);
	[sess_pow, kInd] = getphasepow(channel, sess_events, ...
	                           params.durationMS, ...
			           params.offsetMS, params.bufferMS, ... 
			           'freqs', freq, ... 
				   'filtfreq', params.filtfreq, ... 
				   'filttype', params.filttype, ...
				   'filtorder', params.filtorder, ... 
				   'kthresh', params.kthresh, ...
				   'width', params.width, ...
                                   'resampledRate', params.resampledRate, ...
			           'powonly');
	
	sess_pow = squeeze(sess_pow);			   
	sess_events = sess_events(kInd);
	
	% z-transform
	if params.ztransform
	  baseline = sess_pow(:,baseSamp);
	  base_mean = mean(baseline(:));
	  base_std = std(baseline(:));
	  sess_pow = (sess_pow - base_mean)./base_std;
	end
	
	% average over bins
	sess_bin_pow = NaN(length(sess_events), nBins);
	for b=1:nBins
	  sess_bin_pow(:,b) = nanmean(sess_pow(:,binSamp(b,:)),2);
	end
	
	% concatenate sessions
	chan_pow = [chan_pow; sess_bin_pow];
	chan_events = [chan_events sess_events];
	
      end % session
      
    end % subj

    % get the regressors and do the anova
    for j=1:length(params.field)
      group{j} = getStructField(chan_events, params.field(j).name);
    end
    
    fprintf('\nStarting ANOVA...');
    for b=1:nBins
      fprintf('%d ', b);
      [p, Data.t{f,b}, Data.stats{f,b}] = anovan(chan_pow(:,b), group, 'display', 'off');
      for i=1:length(Data.field)
	Data.field(i).p(f,b) = p(i);
      end
    end
    fprintf('\n');
    
    % get average power for desired subsets of events
    for i=1:length(Data.field)
          
      if Data.field(i).plot
	expr = [Data.field(i).name '==varargin{1}'];
	for j=1:length(Data.field(i).label)
	  these_events = inStruct(chan_events, expr, Data.field(i).label(j).value);
	  all_subj_erpow = NaN(length(eeg.subj), nBins);
	  for s=1:length(eeg.subj)
	    subj_events = inStruct(chan_events, 'strcmp(subjectid, varargin{1})', eeg.subj(s).id);
	    all_subj_erpow(s,:) = nanmean(chan_pow(these_events & subj_events,:));
	  end
	  Data.field(i).label(j).pow(f,:) = nanmean(all_subj_erpow);
	end
      end
      
    end
    
  end % freq
  
  % save a frequencies X bins matrix for each channel
  save(eeg.chan(c).anovaFile, 'Data');
  releaseFile(eeg.chan(c).anovaFile);
  save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');
  
end % channel


