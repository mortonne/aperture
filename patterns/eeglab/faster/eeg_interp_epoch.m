function [EEG, rej_epoch_chan, rej_epoch] = eeg_interp_epoch(EEG, ...
                                     eeg_chans, ref_chan, varargin)
%EEG_INTERP_EPOCH   Find and interpolate bad channel-epochs.
%
%  Identifies bad channel-epochs using epoch_channel_properties. If
%  there is a small number of bad channels for a given epoch, they
%  are replaced using interpolation; if there are many bad
%  channels, that epoch is removed.
%
%  [EEG, rej_epoch_chan, rej_epoch] = eeg_interp_epoch(EEG,
%      eeg_chans, ref_chan, ...)

% options
def.amp_diff_thresh = 100;
def.bad_epoch_thresh = floor(length(eeg_chans) / 10);
def.rej_measure = [1 1 1 0];
def.rej_thresh = 4;
def.rej_stat = 'iqr';
def.baseline = [];
def.log_file = '';
def.verbose = false;
opt = propval(varargin, def);

% baseline correction
if ~isempty(opt.baseline)
  EEG = pop_rmbase(EEG, opt.baseline);
end

% mark channel-epochs with amplitude differences above a
% threshold. This ensures that remaining epochs are below a certain
% level of noise, before the less sensitive statistical thresholds
% below
amp_diffs = epoch_amp_diff(EEG, eeg_chans);

rej_opt = struct('measure', opt.rej_measure, ...
                 'z', opt.rej_thresh, ...
                 'stat', opt.rej_stat);

if ~isempty(opt.log_file)
  fid = fopen(opt.log_file, 'w');
  print_log = true;
elseif opt.verbose
  fid = 1;
  print_log = true;
else
  print_log = false;
end

rej_epoch_chan = cell(1, size(EEG.data, 3));
do_reject = cell(1, size(EEG.data, 3));
excluded = false(1, size(EEG.data, 3));
list_prop = epoch_channel_properties(EEG, eeg_chans, ref_chan);
for i = 1:size(EEG.data, 3)
  % channels with large amplitude changes
  high_amp_diff = amp_diffs(:,i) > opt.amp_diff_thresh;
  rejected = min_z(list_prop(:,:,i), rej_opt);
  
  % get full list of excluded channels
  rej_epoch_chan{i} = sort([eeg_chans(high_amp_diff) eeg_chans(rejected)]);

  if print_log
    fprintf(fid, '%d: ', i);
    fprintf(fid, '%d ', rej_epoch_chan{i});
    fprintf(fid, '\n');
  end
  
  if length(rej_epoch_chan{i}) > opt.bad_epoch_thresh
    % if there were a large number of bad channels for this epoch,
    % exclude it completely, and do not interpolate
    excluded(i) = true;
    do_reject{i} = [];
  else
    do_reject{i} = rej_epoch_chan{i};
  end
end

% run interpolation. For each epoch, interpolate bad channels based
% on the good EEG channels (only good channels in eeg_chans are
% used for interpolation calculation)
ext_chans = setdiff(1:EEG.nbchan, eeg_chans);
EEG = h_epoch_interp_spl(EEG, do_reject, ext_chans);

% remove epochs with too many bad electrodes
rej_epoch = find(excluded);
EEG = pop_select(EEG, 'notrial', rej_epoch);
EEG.saved = 'no';

