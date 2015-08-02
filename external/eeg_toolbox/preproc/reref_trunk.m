function reref(fileroots,grids,outdir,taldir)
%REREF - Rereference EEG recording with weights based on grids.
%
% FUNCTION:
%   reref(fileroots,grids,outdir,taldir)
%
% INPUTS:
%   fileroots:  A cell array whose elements are strings containing
%               the roots of EEG files to be referenced (i.e. 
%               the path to one of the channel files without
%               its .XXX extension indicating the channel). You
%               can also pass in an events struct.
%                                
%       grids:  An array of channel numbers of size nGridsX2.  Each 
%               row should contain the first and last number in one grid.
%               For scalp EEG, all electrodes should be treated as
%               one grid.
%
%      outdir:  Path to the directory where rereferenced channel files
%               will be saved.
%
%      taldir:  Path to the directory containing leads.txt and good_leads.txt.
%               Both files should contain a list of electrode numbers,
%               with one electrode per row.  Alternatively, you can pass
%               in a cell array of the form {all, good}, where all and good
%               are arrays containing electrode numbers.
% OUTPUTS:
%   Channel files and a copy of params.txt saved in outdir.
%        
% EXAMPLE:
%   grids = [1 8; 9 24; 25 40; 41 48; 49 56; 57 64];
%
%   % for each unique eegfile in events, rereference using channels in ./tal/good_leads.txt
%   reref(events, grids, './eeg.reref', './tal');

if nargin < 4
  taldir = './tal';
  if nargin < 3
    outdir = './eeg.reref';
  end
end

% create dir
if ~exist(outdir,'dir')
  mkdir(outdir);
end

% load the leads
if isstr(taldir)
  % load from file
  alfile = fullfile(taldir,'leads.txt');
  glfile = fullfile(taldir,'good_leads.txt');
  al = getleads(alfile);
  gl = getleads(glfile);
else
  % get from cell
  al = taldir{1};
  gl = taldir{2};
end

% get the weights
weights = ones(size(gl));
for i = 1:size(grids,1)
  % find the index of those good leads which are in this grid
  idx = find(gl>=grids(i,1) & gl<=grids(i,2));
  
  if length(idx) > 0
    % weight them appropriately
    weights(idx) = weights(idx)/length(idx);
  end
end

% normalize up front
weights=weights/sum(weights); 

% process the fileroots
if isstruct(fileroots)
  % is events struct, so pull out unique file roots
  events = fileroots;
  fileroots = unique(getStructField(events,'eegfile','~strcmp(eegfile,'''')'));
end

% loop over the file roots
for f = 1:length(fileroots)
  fprintf('Processing %s...\n',fileroots{f});
  % make a fake event to load data fromg gete
  event = struct('eegfile',fileroots{f});
  
  % get data info
  [samplerate,nBytes,dataformat,gain] = GetRateAndFormat(event);

  % Load good leads and calc avg
  fprintf('Calculating reference(%d): ',length(gl));
  avg = [];
  for c = 1:length(gl)
    fprintf('%d ',c);
    teeg = gete(gl(c),event,0);
    if isempty(avg)
      avg = (teeg{1}*weights(c));
    else
      avg = avg + (teeg{1}*weights(c));
    end
  end
  fprintf('\n');
  
  % Load all leads, apply avg, and save to new file
  fprintf('Saving rereferenced channels(%d): ',length(al));
  for c = 1:length(al)
    fprintf('%d ',c);
    % load it
    teeg = gete(al(c),event,0);
    
    % apply avg and reverse gain
    teeg{1} = (teeg{1}-avg)./gain;
    
    % save it
    [fdir,fname] = fileparts(fileroots{f});
    filestem = fullfile(outdir,fname);
    chanfile = sprintf('%s.%03i', filestem, al(c));
    % open and write the file
    fid = fopen(chanfile,'wb','l');
    fwrite(fid,teeg{1},dataformat);
    fclose(fid);
  end
  fprintf('\n');
  
  % copy the params if there
  pfile = fullfile(fileparts(fileroots{f}),'params.txt');
  if exist(pfile,'file')
    try
      % copy to new location
      copyfile(pfile,outdir);
      catch
      % try calling unix directly
      unix(sprintf('cp %s %s', pfile, outdir));
    end
  end
  
end
