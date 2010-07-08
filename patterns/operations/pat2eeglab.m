function [ALLEEG, EEG, CURRENTSET] = pat2eeglab(ALLEEG, pat, chanlocs_file)
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

if ~exist('chanlocs_file', 'var')
  chanlocs_file = '~/eeg/HCGSN128.loc';
end

% load the pattern with the dimensions in EEGLAB order
pattern = permute(get_mat(pat), [2 3 1]);
samplerate = get_pat_samplerate(pat);
start_time = pat.dim.time(1).MSvals(1);
end_time = pat.dim.time(end).MSvals(end);

events = get_dim(pat.dim, 'ev');

% import the pattern as segmented data
set_name = sprintf('%s-%s', pat.name, pat.source);
cond_name = pat.dim.ev.name;
comment_str = sprintf('created by pat2eeglab on %s', datestr(now));
EEG = pop_importdata('setname', set_name, ...
                     'data', pattern, ...
                     'dataformat', 'array', ...
                     'subject', pat.source, ...
                     'condition', cond_name, ...
                     'chanlocs', chanlocs_file, ...
                     'xmin', start_time / 1000, ...
                     'srate', samplerate, ...
                     'comments', comment_str);

% sanity check the imported data; will also set dimensions info which
% we didn't define above based on the size of the imported array
[EEG, result] = eeg_checkset(EEG);
if result == 1
  error('problem importing data to EEGLAB.')
end

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

% add RT back in as a field, since pop_importepoch strips it
rt_events = strcmp({EEG.event.type}, 'rt');
[EEG.event.rt] = deal(NaN);      
[EEG.event(rt_events).rt] = deal(events.rt);

% update ALLEEG to add this dataset
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);

