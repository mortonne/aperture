function subj = write_bad_channels(subj, varargin)
%WRITE_BAD_CHANNELS   Identify bad channels and write to a text file.
%
%  subj = write_bad_channels(subj, ...)
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   veog_channels - cell array of channel numbers for VEOG pairs.
%                   ({[8 126] [25 127]})
%   heog_channels - numbers for a HEOG channel pair. ([1 32])
%   thresh_m      - channels will be excluded if the z-score (across
%                   channels) of their mean exceeds this threshold. (4)
%   thresh_sd     - channels will be excluded if the z-score of their
%                   standard deviation exceeds this threshold. (4)
%   eeg_dir       - path to the EEG files to examine, relative to each
%                   session directory, e.g. subj.sess(1).dir.
%                   ('/eeg/eeg.noreref')

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

% options (channel numbers for EGI HCGSN128)
defaults.veog_channels = {[8 126] [25 127]};
defaults.heog_channels = [1 32];
defaults.thresh_m = 4;
defaults.thresh_sd = 4;
defaults.eeg_dir = '/eeg/eeg.noreref';
params = propval(varargin, defaults);

channels = [subj.chan.number];

for i = 1:length(subj.sess)
  files = get_eeg_files(fullfile(subj.sess(i).dir, params.eeg_dir));
  bad = bad_channels(files, channels, params.heog_channels, ...
                     params.veog_channels, params.thresh_m, ...
                     params.thresh_sd);
  
  % get channel numbers for all electrodes that were bad for any of the
  % EEG files (could save one for each file, but this will be very
  % similar and is simpler)
  bad_chans = channels(any(bad, 1));
  
  % write to a standard bad channels file
  file = fullfile(subj.sess(i).dir, params.eeg_dir, 'bad_chan.txt');
  write_chans_file(file, bad_chans);
end


function files = get_eeg_files(eegdir, basename, ext)
  %GET_EEG_FILES   Find EEG files.
  %
  %  files = get_eeg_files(eegdir, basename, ext)
  %
  %  Returns a cell array of paths to files that match the
  %  criteria. If an extension is specified, the returned
  %  filenames will include the file extension; otherwise,
  %  the extension will be omitted.
  
  %input checks
  if ~exist('eegdir', 'var') || ~ischar(eegdir)
    error('You must give the path to a directory.')
  elseif ~exist(eegdir, 'dir')
    error('Directory does not exist: %s', eegdir)
  end
  if ~exist('basename', 'var')
    basename = '*';
  end
  if ~exist('ext', 'var')
    ext = '.001';
    clip_ext = true;
  else
    clip_ext = false;
  end
  
  file = {};
  
  % search
  pattern = fullfile(eegdir, [basename ext]);
  d = dir(pattern);
  if isempty(d)
    error('no files found that match: %s', pattern)
  end
  
  % get the complete paths
  for i = 1:length(d)
    if clip_ext
      [pathstr, name] = fileparts(d(i).name);
      files{i} = fullfile(eegdir, name);
    else
      files{i} = fullfile(eegdir, d(i).name);
    end
  end
