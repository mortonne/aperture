function pow_anova_iEEG(eeg, resDir, params)
%
%EXPLORE_POW - gets power spectra for each channel, then 
%calculates significance
%
% FUNCTION: explore_pow(erpow, doSubjSig, doGA, doGaSig)
%
% INPUT: erpow - struct created by running init_iEEG or init_scalp, with an
%        additional erpow.filts.evtype field containing masks
%        containing expressions corresponding to the filtering
%        criteria of the types of events to be compared
% 
% OUTPUT: power values with significance, saved by
%         channel in 'erpow.resDir/'
%

if nargin<2
  params = [];
end

% set the defaults for params
params = structDefaults(params,  'anaType', 'pow_anova_iEEG',  'eventFilter', '',  'freqs', 2.^((8:48)/8),  'offsetMS', -200,  'durationMS', 1800,  'binSizeMS', 100,  'baseEventFilter', '',  'baseOffsetMS', -200,  'baseDurationMS', 200,  'filttype', 'stop',  'filtfreq', [58 62],  'filtorder', 4,  'bufferMS', 1000,  'resampledRate', 500,  'width', 6,  'kthresh', 5,  'ztransform', 1,  'replace_eegFile', '');

% add optional eventFilters if desired
if isfield(params, 'XDpractice') && ~isempty(params.XDpractice)
  if ~isempty(params.eventFilter)
    params.eventFilter = [params.eventFilter ' & '];
  end
  params.eventFilter = [params.eventFilter '(session>' num2str(params.XDpractice(1)) ' | list>' num2str(params.XDpractice(2)) ')'];
end

if isfield(params, 'artThresh') && ~isempty(params.artThresh)
  if ~isempty(params.eventFilter)
    params.eventFilter = [params.eventFilter ' & '];
  end
  params.eventFilter = [params.eventFilter '(artifactMS<0 | artifactMS>' num2str(params.artThresh) ')'];
end

% add params to the eeg struct
eeg.params = params;
eeg.resDir = resDir;

disp(params);

% get time bins in samples
durationSamp = fix(params.durationMS*params.resampledRate./1000);
binSizeSamp = fix(params.binSizeMS*params.resampledRate./1000);
nBins = fix(durationSamp/binSizeSamp);

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

% if any subjects need to be excluded, take them out
if isfield(params, 'XDsubj')
  for i=1:length(params.XDsubj)
    filterStruct(eeg.subj, '~strcmp(id, varargin{1})', params.XDsubj{i});
  end
end

% step through subjects
for s=1:length(eeg.subj)

  fprintf('\nStarting Power ANOVA for %s:', eeg.subj(s).id);

  % prepare subject's results directory
  eeg.subj(s).resDir = fullfile(resDir, eeg.subj(s).id);
  if ~exist(fullfile(eeg.subj(s).resDir, 'data'), 'dir');
    mkdir(fullfile(eeg.subj(s).resDir, 'data'));
  end    

  for n=1:length(eeg.subj(s).sess)
    sess_events = loadEvents(eeg.subj(s).sess(n).eventsFile, params.replace_eegFile);
    events{n} = filterStruct(sess_events, params.eventFilter);
    if params.ztransform
      base_events{n} = filterStruct(sess_events, params.baseEventFilter);
    end
  end
  
  % step through channels 
  for c=1:length(eeg.subj(s).channels)
    channel = eeg.subj(s).chan(c).number;
    
    eeg.subj(s).chan(c).powAnovaData = fullfile(eeg.subj(s).resDir, 'data', [eeg.subj(s).id '_chan' num2str(channel) '.mat']);
    % if this channel has been or is being processed, skip to the next
    if ~lockFile(eeg.subj(s).chan(c).powAnovaData)
      save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg'); % update eeg
      continue
    end
    
    fprintf('\n***Channel %d***\n', channel);   
    fprintf('\nLoading power values...\n');
    
    Data = Temp;
    chan_pow = [];
    chan_events = [];
    
    % loop through sessions, so each can be individually z-transformed
    for n=1:length(eeg.subj(s).sess)
      if ~ismember(channel, eeg.subj(s).sess(n).goodChans)
	continue
      end
      fprintf('%s\n', eeg.subj(s).sess(n).eventsFile);      
      
      if params.ztransform
	for f=1:length(params.freqs)
	  base_pow = getphasepow(channel, base_events{n}, ...
	                         params.baseDurationMS, ...
			         params.baseOffsetMS, params.bufferMS, ... 
			         'freqs', params.freqs(f), ... 
				 'filtfreq', params.filtfreq, ... 
				 'filttype', params.filttype, ...
				 'filtorder', params.filtorder, ... 
				 'kthresh', params.kthresh, ...
				 'width', params.width, ...
                                 'resampledRate', params.resampledRate, ...
			         'powonly');
	  
	  base_mean(f) = nanmean(base_pow(:));
	  base_std(f) = nanstd(base_pow(:));	   
	end
      end
      
      % get the desired events for this subj, this sess
      [sess_pow, kInd] = getphasepow(channel, events{n}, ...
	                             params.durationMS, ...
			             params.offsetMS, params.bufferMS, ... 
			             'freqs', params.freqs, ... 
				     'filtfreq', params.filtfreq, ... 
				     'filttype', params.filttype, ...
				     'filtorder', params.filtorder, ... 
				     'kthresh', params.kthresh, ...
				     'width', params.width, ...
                                     'resampledRate', params.resampledRate, ...
			             'powonly');
                                           
      sess_events = sess_events(kInd);
      
      % z-transform each freq separately
      if params.ztransform
	for f=1:length(params.freqs)
	  sess_pow(:,f,:) = (sess_pow(:,f,:) - base_mean(f))./base_std(f);
	end
      end
	
      % average over bins
      sess_bin_pow = NaN(length(sess_events), nBins);
      for b=1:nBins
	sess_bin_pow(:,:,b) = nanmean(sess_pow(:,:,binSamp(b,:)),3);
      end      
      
      % concatenate sessions
      chan_pow = [chan_pow; sess_bin_pow];
      chan_events = [chan_events sess_events];
	
    end % session

    % get the regressors and do the anova
    for j=1:length(params.field)
      group{j} = getStructField(chan_events, params.field(j).name);
    end
    
    fprintf('\nStarting ANOVA...\nFrequency: ')
    for f=1:length(params.freqs)
      fprintf('%.2f ',params.freqs(f)) 
      for b=1:nBins
	[p, Data.t{f,b}, Data.stats{f,b}] = anovan(chan_pow(:,f,b), group, 'display', 'off');
	for i=1:length(Data.field)
	  Data.field(i).p(f,b) = p(i);
	end
      end
    end
    fprintf('\n');
    
    % get average power for desired subsets of events
    for i=1:length(Data.field)

      if Data.field(i).plot
	expr = [Data.field(i).name '==varargin{1}'];
	for j=1:length(Data.field(d).label)
	  these_events = inStruct(chan_events, expr, Data.field(i).label(j).value);
	  Data.field(i).label(j).pow = squeeze(nanmean(chan_pow(these_events,:,:)));
	end
      end
      
    end
    
    % save a frequencies X bins matrix for each channel
    save(eeg.subj(s).chan(c).powAnovaData, 'Data');
    releaseFile(eeg.subj(s).chan(c).powAnovaData);
    save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg'); % update eeg
    
  end % channel

end % subj


