function EEG = pat2eeglab(pat, chanlocs_file)
%PAT2EEGLAB   Convert a pattern object to EEGLAB format.
%
%  Prepare a pattern object for interactive visualization/analysis in
%  EEGLAB. EEGLAB's GUI accesses standard variables that are expected to
%  be defined in the base workspace. Hence, you must capture all the
%  ouput variables, and give them the names used in this docstring.
%  Otherwise, EEGLAB won't be able to find them.
%
%  EEGLAB is expected to already be started when this function is run.
%  ALLEEG should automatically be defined in the base workspace. After
%  the function is run, ALLEEG, EEG, and CURRENTSET will be updated.
%  Then you must run "eeglab redraw" to update the EEGLAB GUI with the
%  new data. Multiple patterns may be imported, and they will all become
%  available under the "Datasets" menu.
%
%  [ALLEEG, EEG, CURRENTSET] = pat2eeglab(ALLEEG, pat, chanlocs_file)
%
%  INPUTS:
%         ALLEEG:  EEGLAB standard variable that tracks all current
%                  datasets.
%
%            pat:  an eeg_ana pattern object.
%
%  chanlocs_file:  path to a file containing channel locations. Default:
%                  '~/eeg/HCGSN128.loc'
%
%  OUTPUTS:
%      ALLEEG:  EEGLAB array of datasets, with the new EEG structure
%               added.
%
%         EEG:  EEGLAB EEG structure, containing dataset information.
%
%  CURRENTSET:  index of the currrent EEGLAB dataset.
%
%  NOTES:
%   For convenience, currently assumes that events will contain "rt"
%   and "artifactMS" fields with ms values, and EEGLAB will create
%   events corresponding to these times. Later, will generalize this
%   feature.

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
end_time = time(end).range(end);

events = get_dim(pat.dim, 'ev');

% import the pattern as segmented data
set_name = sprintf('%s-%s', pat.name, pat.source);
%cond_name = pat.dim.ev.name;
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

%figure
%pop_plottopo(EEG, [1:129] , 'words', 0, 'ylim', [-10 10]);

% NaN out latency fields that are past the end of the epoch
[events([events.rt] > end_time).rt] = deal(NaN);
art = [events.artifactMS];
[events(art > end_time | art <=1 ).artifactMS] = deal(NaN);

% import events information
events_cell = struct2cell(events')';
EEG = pop_importepoch(EEG, events_cell, fieldnames(events), ...
                      'typefield', 'type', ...
                      'latencyfields', {'rt', 'artifactMS'}, ...
                      'timeunit', 0.001);

% add latency fields back in, since pop_importepoch strips them
word_events = strcmp({EEG.event.type}, 'WORD');
[EEG.event.rt] = deal(NaN);
[EEG.event(word_events).rt] = deal(events.rt);

%art_events = strcmp({EEG.event.type}, 'artifactMS');
[EEG.event.artifactMS] = deal(NaN);
[EEG.event(word_events).artifactMS] = deal(events.artifactMS);

