function reref(fileroot, grids, goodchans, outdir)
%REREF - Rereference EEG recording with weights based on grids.
%
% FUNCTION:
%   reref(fileroot, grids, goodchans, outdir)
%
% INPUTS:
%    fileroot:  The root of the EEG files to be referenced (i.e. 
%               the path to one of the channel files without
%               its .XXX extension indicating the channel).
%
%       grids:  A cell array where each element contains an array
%               of channel numbers corresponding to one grid.
%               For scalp EEG, all electrodes should be treated as
%               one grid. Channels that are not listed in any grid
%               will not be rereferenced.
%
%   goodchans:  An array of channel numbers indicating channels that
%               will be included in the calculation of the average
%               reference. Default: [grids{:}]
%
%      outdir:  Path to the directory where rereferenced channel files
%               will be saved.
%
% OUTPUTS:
%   Rereferenced EEG files and a copy of params.txt saved in outdir.
% 
% EXAMPLE:
%  % define the grids
%  grids = {1:8, 9:24, 25:40, 41:48, 49:56, 57:64};
%
%  % get the channels that were good for this patient
%  goodchans = getleads('tal/good_leads.txt');
%
%  % rereference one set of EEG files
%  reref(fileroot, grids, goodchans, 'eeg.reref');

% input checks!
if ~exist('fileroot','var') || ~ischar(fileroot)
  error('You must give the path to EEG files to rereference.')
elseif ~exist('grids','var') || ~iscell(grids)
  error('You must pass a grids cell array.')
elseif any(cellfun('size', grids, 1)>1)
  error('Each cell of grids must contain a row vector.')
end
if ~exist('goodchans','var')
  goodchans = [grids{:}];
elseif ~isnumeric(goodchans)
  error('goodchans must be a numeric array.')
elseif any(~ismember(goodchans, [grids{:}]))
  error('goodchans contains channels that are not in grids.')
end
if ~exist('outdir','var')
  outdir = './eeg.reref';
end
if ~exist(outdir,'dir')
  mkdir(outdir);
end

% weight within each grid
gl = goodchans;
weights = ones(size(gl));
for i = 1:length(grids)
  % find the index of those good leads which are in this grid
  idx = find(ismember(gl, grids{i}));
  
  if ~isempty(idx)
    % weight them appropriately
    weights(idx) = weights(idx)/length(idx);
  end
end

% normalize the weights across all grids
weights = weights/sum(weights);

fprintf('Processing %s...\n',fileroot);
% make a fake event to load data from gete
event = struct('eegfile',fileroot);

% Load good leads and calc avg
fprintf('Calculating reference(%d): ',length(gl));
avg = 0;
for i=1:length(gl)
  fprintf('%d ', gl(i));
  teeg = gete(gl(i), event, 0);
  if i~=1 && length(teeg{1})~=length(avg)
    error('eeg_toolbox:reref:CorruptedEEGFile', ...
          'Length of EEG for channel %d is less than the other channels. EEG file may be corrupted', ...
          gl(i))
  end
  
  avg = avg + (teeg{1}*weights(i));
end
fprintf('\n');

% prepare to write rereferenced channels
[samplerate,nBytes,dataformat,gain] = GetRateAndFormat(event);
al = [grids{:}];
[fdir,fname] = fileparts(fileroot);
filestem = fullfile(outdir,fname);

% load all leads, apply avg, and save to new file
fprintf('Saving rereferenced channels(%d): ',length(al));
for channel=al
  fprintf('%d ',channel);
  % load it
  teeg = gete(channel,event,0);

  % apply avg and reverse gain
  teeg{1} = (teeg{1}-avg)./gain;

  % save it
  chanfile = sprintf('%s.%03i', filestem, channel);
  fid = fopen(chanfile,'wb','l');
  fwrite(fid,teeg{1},dataformat);
  fclose(fid);
end
fprintf('\n');

% copy the params if there
pfile = fullfile(fdir, 'params.txt');
if exist(pfile,'file')
  try
    % copy to new location
    copyfile(pfile,outdir);
  catch
    % try calling unix directly
    unix(sprintf('cp %s %s', pfile, outdir));
  end
end
