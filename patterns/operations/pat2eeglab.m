function EEG = pat2eeglab(pat, chanlocs_file)
%PAT2EEGLAB   Convert a pattern object to EEGLAB format.
%
%  If you are using the EEGLAB GUI, you must use eeg_store to update
%  variables used by the GUI after calling this function.
%
%  EEG = pat2eeglab(pat, chanlocs_file)
%
%  INPUTS:
%            pat:  an eeg_ana pattern object.
%
%  chanlocs_file:  path to a file containing channel locations. Default:
%                  '~/eeg/HCGSN128.loc'
%
%  OUTPUTS:
%      EEG:  EEGLAB EEG structure, containing dataset information.

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

if ~exist('chanlocs_file', 'var')
  chanlocs_file = 'HCGSN128.loc';
end

% load the pattern with the dimensions in EEGLAB order
pattern = permute(get_mat(pat), [2 3 1]);
samplerate = get_pat_samplerate(pat);

time = get_dim(pat.dim, 'time');
start_time = time(1).range(1);

% import the pattern as segmented data
set_name = sprintf('%s-%s', pat.name, pat.source);
cond_name = pat.name;
comment_str = sprintf('created by pat2eeglab on %s', datestr(now));
EEG = pop_importdata('data', pattern, ...
                     'setname', set_name, ...
                     'srate', samplerate, ...
                     'pnts', patsize(pat.dim, 'time'), ...
                     'xmin', start_time / 1000, ...
                     'nbchan', patsize(pat.dim, 'chan'), ...
                     'subject', pat.source, ...
                     'ref', 'Cz', ...
                     'chanlocs', chanlocs_file, ...
                     'comments', comment_str);

% import events information
events = get_dim(pat.dim, 'ev');
events_cell = struct2cell(events')';
EEG = pop_importepoch(EEG, events_cell, fieldnames(events), ...
                      'typefield', 'type', ...
                      'timeunit', 0.001);

