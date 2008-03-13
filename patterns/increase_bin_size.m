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
[time, bint] = timeBins(pat.dim.time, params);

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
  
  % get the pat obj for the original pattern
  pat1 = getobj(exp.subj(s), 'pat', params.patname);  
  
  % set where the pattern will be saved
  patfile = fullfile(resDir, 'data', [exp.subj(s).id '_' patname '.mat']);
  
  % check input files and prepare output files
  if prepFiles(pat1.file, patfile, params)~=0
    continue
  end
  
  % get event info
  ev = pat1.dim.ev;
  if ~isempty(params.eventFilter) % we'll need to save a new events struct
    ev.file = fullfile(resDir, 'data', [exp.subj(s).id '_' patname '_events.mat']);
  end

  % divide the channels into regions to be averaged over later
  [chan, binc] = chanBins(pat1.dim.chan, params);

  % create a pat object to keep track of this pattern
  pat = init_pat(patname, patfile, params, ev, chan, time, freq);
  
  % update exp with the new pat object
  exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat);
  
  % load the original pattern, initialize the new pattern
  [pattern1, events] = loadPat(pat1, params, 1);
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
    save(pat2.dim.ev.file, 'events')
  end
end % subj