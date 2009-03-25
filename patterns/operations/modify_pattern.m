function [pat,pattern,events] = modify_pattern(pat, params, pat_name, res_dir)
%MODIFY_PATTERN   Modify an existing pattern.
%
%  [pat, pattern, events] = modify_pattern(pat, params, pat_name, res_dir)
%
%  Use this function to modify existing patterns. You can either save the
%  new pattern under a different name and/or file, or overwrite the old
%  one.
%
%  Operations are run in this order: 1) filtering, 2) binning, 3) principle
%  components analysis, 4) saving out in slices
%
%  INPUTS:
%       pat:  a pattern object.
%
%    params:  a structure specifying options for modifying the pattern.
%             See below.
%
%  pat_name:  string identifier for the new pattern. If this is the same
%             as pat.name, or if pat_name is not specified, the old
%             pattern will be replaced.
%
%   res_dir:  directory where the new pattern will be saved.
%
%  OUTPUTS:
%       pat:  a modified pattern object, named pat_name.
%
%   pattern:  the modified pattern.
%
%    events:  modified events.
%
%  PARAMS:
%  Filtering
%   eventFilter - input to filterStruct; used to filter the events dimension
%   chanFilter  - filter for the channels dimension
%   chan_filter - filter that uses filter_struct instead of filterStruct
%   timeFilter  - filter for the time dimension
%   freqFilter  - filter for the frequency dimension
%
%  Artifact Rejection
%   excludeBadChans - if true, channels whose numbers are listed in
%                     fileparts(events.eegfile)/bad_chan.txt
%                     will be excluded for the relevant events
%   absThresh       - if any value in an event crosses this this threshold
%                     (either positive or negative), the event will be
%                     excluded for that channel
%
%  Binning
%   field          - input to make_event_bins
%   eventbinlabels - cell array of strings, with one cell per bin. Gives
%                    a label for each event bin, which appears in the
%                    'label' field of the modified events structure
%   chanbins       - 
%   chanbinlabels  - cell array of strings
%   MSbins         - [N bins X 2] array, where MSbins(Y,1) gives the start
%                    of bin Y in milliseconds, and MSbins(Y,2) gives the
%                    end of the bin
%   MSbinlabels    - cell array of strings
%   freqbins       - bins in Hz for the frequency dimension, specified in 
%                    the same format as MS bins
%   freqbinlabels  - cell array of string labels
%
%  PCA
%   nComp - number of principal components to extract
%
%  Slicing
%   splitDim - dimension along which to split the pattern into slices;
%              the pattern will be saved with one file per slice
%
%  EXAMPLE:
%   % calculate averages for recalled and not recalled events
%   params.field = 'recalled';
%   pat = getobj(subj, 'pat', 'voltage');
%
%   % get the average for each unique value of the 'recalled' field
%   % of events, and overwrite the old pattern
%   pat = modify_pattern(pat, params);

% input checks
if ~exist('pat','var')
  error('You must pass a pattern object.')
  elseif ~isstruct(pat)
  error('pat must be a structure.')
  elseif isempty(pat)
  error('The input pat object is empty.')
end
if ~exist('params','var')
  params = struct;
end
if ~exist('pat_name','var') | isempty(pat_name)
  % default to overwriting the existing pattern
  pat_name = pat.name;
end
if ~exist('res_dir','var')
  % get the path to the pattern's file
  if iscell(pat.file)
    temp = pat.file{1};
    else
    temp = pat.file;
  end
  % set the default results directory
  res_dir = fullfile(fileparts(fileparts(fileparts(temp))), pat_name);
end

% default parameters
params = structDefaults(params, ...
                        'nComp',           [], ...
                        'excludeBadChans', 0,  ...
                        'absThresh',       [], ...
                        'overwrite',       0,  ...
                        'lock',            0,  ...
                        'splitDim',        [], ...
                        'savePat',         1);

oldpat = pat;

% set the file in which to save the new pattern
if ~strcmp(oldpat.name, pat_name)
  % if the pat_name is different, save the pattern to a new file
  patfile = fullfile(res_dir, 'patterns', objfilename('pattern', pat_name, pat.source));
  else
  patfile = oldpat.file;
end

try
  % check input files and prepare output files
  prepFiles(oldpat.file, patfile, params);
catch err
  % something is wrong with i/o
  if strfind(err.identifier, 'fileExists')
    return
    elseif strfind(err.identifier, 'fileNotFound')
    rethrow(err)
    elseif strfind(err.identifier, 'fileLocked')
    rethrow(err)
  end
end

% initialize the new pat object
pat = init_pat(pat_name,patfile,oldpat.source,combineStructs(params,oldpat.params),oldpat.dim);
if isfield(oldpat,'stat')
  pat.stat = oldpat.stat;
end

% load the pattern
[pattern, events] = load_pattern(oldpat, params);

fprintf('modifying pattern %s...', oldpat.name)

% apply filters
[pat,inds,events,evmod(1)] = patFilt(pat,params,events);
pattern = pattern(inds{:});

% ARTIFACT FILTERS
if params.excludeBadChans
  % load bad channel info
  [bad_chans, event_ind] = get_bad_chans({events.eegfile});
  
  % get current channel numbers
  chan_numbers = [pat.dim.chan.number];
  
  % combine channel and event info to make a bad channels logical array
  isbad = mark_bad_chans(chan_numbers, bad_chans, event_ind);

  % expand isbad to the same dimensions as pattern
  patsize = size(pattern);
  isbad = repmat(isbad, [1 1 patsize(3:end)]);
  
  % mark bad parts of the pattern
  pattern(isbad) = NaN;
end

if params.absThresh
  % find any values that are above our absolute threshold
  bad_samples = abs(pattern)>params.absThresh;
  
  % get a logical indicating events/channels that have at least 
  % one bad sample
  pat_size = size(pattern);  
  bad_event_chans = any(reshape(bad_samples, pat_size(1), pat_size(2), prod(pat_size(3:end))), 3);
  
  isbad = repmat(bad_event_chans, [1 1 pat_size(3:end)]);
  
  % mark the bad events/channels
  pattern(isbad) = NaN;
  
  % check the results
  fprintf('Threw out %d event-channels out of %d with abs. val. greater than %d.\n', sum(bad_event_chans(:)),prod(pat_size(1:2)),params.absThresh)
  
  % get channels that are bad for all events
  bad_chans = find(all(bad_event_chans,1));
  if ~isempty(bad_chans)
    emsg = ['channels excluded: ' sprintf('%d ', pat.dim.chan(bad_chans).label)];
    warning(emsg)
  end
end

% BINNING
[pat,patbins,events,evmod(2)] = patBins(pat,params,events);
pattern = patMeans(pattern, patbins);

% PCA
if ~isempty(params.nComp)
  % run PCA on the pattern
  [pat, pattern, coeff] = patPCA(pat, params, pattern);
  coeffFile = fullfile(res_dir, 'patterns', objfilename('coeff', pat_name, pat.source));
  pat.dim.coeff = coeffFile;
  save(pat.dim.coeff, 'coeff');
end

if strcmp(oldpat.name, pat.name)
  fprintf('saved.')
  else
  fprintf('saved as "%s".\n', pat.name)
end

if params.savePat
  if any(evmod)
    if ~exist(fullfile(res_dir, 'events'), 'dir')
      mkdir(fullfile(res_dir, 'events'));
    end

    % we need to save a new events struct
    pat.dim.ev.file = fullfile(res_dir, 'events', objfilename('events', pat_name, pat.source));  
    save(pat.dim.ev.file, 'events');
  end

  % save the new pattern
  save(pat.file, 'pattern');
  
  % resave in slices
  if ~isempty(params.splitDim)
    pat = split_pattern(pat, params.splitDim);
    else
    pat.dim.splitdim = [];
  end
end
