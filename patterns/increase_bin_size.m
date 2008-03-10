function exp = increase_bin_size(exp, params, patname, resDir)
%
%INCREASE_BIN_SIZE - average over adjacent time or frequency bins
%to decrease the size of patterns, or average over channels for ROI
%analyses; new patterns will be saved in a new directory
%
% FUNCTION: exp = increase_bin_size(exp, params, patname, resDir)
%
% INPUT: exp - struct created by init_iEEG or init_scalp
%        params - required fields: patname (specifies the name of
%                 which pattern in the exp struct to use)
%
%                 optional fields: eventFilter (specify subset of
%                 events to use), masks (cell array containing
%                 names of masks to apply to pattern)
%        resDir - 'pattern' files are saved in resDir/data
%        patname - name of new pattern to save under in the exp struct
%
% OUTPUT: new exp struct with ana object added, which contains file
% info and parameters of the analysis
%

%exp = increase_bin_size(exp, params, resDir, patname)
%
%EXAMPLES: params.binChan = {'LF', 'RF'} OR {{'LF', 'LFp'}, {'RF',
%'RFp'}} OR {[1 2 125], [45 35 76 17 18]}
%          params.MSbins = [0 100; 100 200]
%          params.freqbins = [2 4; 4 8]
%

if ~isfield(params, 'patname')
  error('You must specify which pattern to use');
end
if ~exist('patname', 'var')
  patname = [params.patname '_mod'];
end
if ~exist('resDir', 'var')
  resDir = fullfile(exp.resDir, patname);
end

params = structDefaults(params, 'MSbinlabels', {},  'chanbinlabels', {},  'freqbinlabels', {});

% time and freq dimensions should be same for all subjects
pat1 = getobj(exp.subj(1), 'pat', params.patname);

% make the new time bins (if applicable)
if isfield(params, 'MSbins') && ~isempty(params.MSbins)
  for t=1:length(params.MSbins)
    bint{t} = find(inStruct(pat1.dim.time, 'avg>=varargin{1} & avg<varargin{2}', params.MSbins(t,1), params.MSbins(t,2)));
    
    % get ms value for each sample in the new time bin
    allvals = [];
    for i=1:length(bint{t})
      allvals = [allvals pat1.dim.time(bint{t}(i)).MSvals];
    end    
    time(t).MSvals = allvals;
    time(t).avg = mean(allvals);
    
    % update the time bin label
    if ~isempty(params.MSbinlabels)
      time(t).label = params.MSbinlabels{t};
    else
      time(t).label = [num2str(time(t).MSvals(1)) ' to ' num2str(time(t).MSvals(end)) 'ms'];
    end
  end

else % time dim doesn't change
  for t=1:length(pat1.dim.time)
    bint{t} = t;
  end
  time = pat1.dim.time;
end

% make the new frequency bins
if isfield(params, 'freqbins') && ~isempty(params.freqbins)
  for f=1:length(params.freqbins)
    % define the new bins
    binf{f} = find(inStruct(pat1.dim.freq, 'avg>=varargin{1} & avg<varargin{2}', params.freqbins(f,1), params.freqbins(f,2)));
    
    allvals = [];
    for i=1:length(binf{f})
      allvals = [allvals pat1.dim.freq(binf{f}(i)).vals];
    end    
    freq(f).vals = allvals;
    freq(f).avg = mean(allvals);
    
    % update the frequency label
    if ~isempty(params.freqbinlabels)
      freq(f).label = params.freqbinlabels{f};
    else
      freq(f).label = [num2str(freq(f).vals(1)) ' to ' num2str(freq(f).vals(end)) 'Hz'];
    end
  end
  
elseif isfield(pat1.dim, 'freq') && ~isempty(pat1.dim.freq)
  for f=1:length(pat1.dim.freq)
    binf{f} = f;
  end
  freq = pat1.dim.freq;
  
else % there is no frequency dimension
  binf{1} = 1;
  freq = [];
end

% create the new pattern for each subject
for s=1:length(exp.subj)
  fprintf('%s\n', exp.subj(s).id);
  
  pat1 = getobj(exp.subj(s), 'pat', params.patname);
  
  % initialize the new pat
  pat2.name = patname;
  pat2.file = fullfile(resDir, 'data', [exp.subj(s).id '_' patname '.mat']);
  pat2.params = params;
  
  % check input files and prepare output files
  if prepFiles(pat1.file, pat2.file, params)~=0
    continue
  end
  
  % get event info
  event = pat1.dim.event;
  if ~isempty(params.eventFilter)
    event.file = fullfile(resDir, 'data', [exp.subj(s).id '_' patname '_events.mat']);
  end
  
  % make new channel bins
  if isfield(params, 'chanbins')
    
    for c=1:length(params.chanbins)
      % define the new channel bins
      if isnumeric(params.chanbins{c})
	binc{c} = find(inStruct(pat1.dim.chan, 'ismember(number, varargin{1})', params.chanbins{c}));
      elseif iscell(params.chanbins{c})
	binc{c} = find(inStruct(pat1.dim.chan, 'ismember(region, varargin{1})', params.chanbins{c}));
      else
	binc{c} = find(inStruct(pat1.dim.chan, 'strcmp(region, varargin{1})', params.chanbins{c}));
      end
      chans = pat1.dim.chan(binc{c});
      
      % update the channel labels
      chan(c).number = getStructField(chans, 'number');
      chan(c).region = getStructField(chans, 'region');
      if ~isempty(params.chanbinlabels)
	chan(c).label = params.chanbinlabels{c};
      end
      
    end
  else % no averaging across channels
    for c=1:length(pat1.dim.chan)
      binc{c} = c;
      chan = pat1.dim.chan;
    end
  end

  % add all dimension info to the new pat
  pat2.dim = struct('event', event, 'chan', chan, 'time', time, 'freq', freq);
  
  % update exp with the new pat object
  exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat2);
  
  % load the original pattern and corresponding events
  [pattern1, events] = loadPat(pat1, params, 1);
  
  % initalize the new pat
  pattern = NaN(size(pattern1,1), length(binc), length(bint), length(binf));
  
  % do the averaging
  for f=1:length(binf)
    fmean = nanmean(pattern1(:,:,:,binf{f}),4);
    for t=1:length(bint)
      fprintf('%d.', t);
      tmean = nanmean(fmean(:,:,bint{t}),3);
      for c=1:length(binc)
	pattern(:,c,t,f) = nanmean(tmean(:,binc{c}),2);
      end
    end
  end
  fprintf('\n');

  % save the new pattern
  closeFile(pat2.file, 'pattern');
  if ~isempty(params.eventFilter)
    save(pat2.dim.event.file, 'events')
  end
end % subj