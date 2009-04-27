function channels = read_chans_file(file)
%READ_CHANS_FILE   Read in a standard channels file.
%
%  channels = read_chans_file(file)
%
%  INPUTS:
%      file:  path to a text file containing channel numbers.
%             There should be one channel per row. The file
%             may contain shell-style comments (i.e. everything
%             on a line after a "#" will be ignored).
%
%  OUTPUTS:
%  channels:  vector of channel numbers.

% input checks
if ~exist('file','var')
  error('You must pass the path to a bad channels file.')
elseif ~exist(file,'file')
  error('file does not exist: %s', file)
end

fid = fopen(file);

% read the file, omitting shell-style comments
c = textscan(fid, '%d', 'CommentStyle', '#');
channels = c{1};

fclose(fid);
