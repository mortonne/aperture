function pat = faster_pattern(pat, varargin)
%FASTER_PATTERN   Remove artifacts using FASTER.
%
%  pat = faster_pattern(pat, ...)
%
%  INPUTS:
%      pat:  input pattern object.
%
%  OUTPUTS:
%      pat:  filtered pattern object, with updated pattern matrix and
%            associated metadata.
%
%  OPTIONS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   save_mats    - if true, and input mats are saved on disk, modified
%                  mats will be saved to disk. If false, the modified
%                  mats will be stored in the workspace, and can
%                  subsequently be moved to disk using move_obj_to_hd.
%                  (true)
%   overwrite    - if true, existing patterns on disk will be
%                  overwritten. (false)
%   save_as      - string identifier to name the modified pattern. If
%                  empty, the name will not change. ('')
%   res_dir      - directory in which to save the modified pattern and
%                  events, if applicable. Default is a directory named
%                  pat_name on the same level as the input pat.

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

% options
%def.eog_pairs = {[8 126] [25 127] [1 32] [8 17] [25 17]};
%def.locs_file = 'HCGSN128_eog_ob.loc';
%def.eog_pairs = {[8 126] [25 127] [1 32]};
def.emg_band = [20 50];
def.locs_file = 'HCGSN128.loc';
def.epoch_thresh = 100;
def.epoch_chan_thresh = 150;
def.bad_chan_thresh = 12;
def.job_file = 'faster_overlap.eegjob';
def.res_dir = '';
def.save_intermediate = false;
def.plot_epoch_rej = false;
def.eeg_chans = 1:129;
def.ref_chan = 129;
def.veog_chans = [126 127];
def.epoch_overlap = true;
[opt, saveopt] = propval(varargin, def);

% mod_pattern handles file management
pat = mod_pattern(pat, @run_faster, {opt}, saveopt);

function pat = run_faster(pat, opt)

  %% prepare files

  % add HEOG and VEOG channels
  pat_file = pat.file;
  % pat = move_obj_to_workspace(pat);
  % eog_pat = diff_pattern(pat, 'chans', opt.eog_pairs);
  % pat = cat_patterns([pat eog_pat], 'chan', 'save_mats', false);
  
  % export to EEGLAB
  if isempty(opt.res_dir)
    opt.res_dir = get_pat_dir(pat, ['faster_' pat.source]);
  end
  cd(opt.res_dir)
  
  % start up EEGLAB (or restart if already running; this might affect
  % previously loaded datasets, so save before running this function)
  eeglab
  EEG = pat2eeglab(pat, opt.locs_file);
  
  % add EOG and EMG channels
  n_prev = EEG.nbchan;
  EEG = eog_pairs(EEG);
  eog_chans = (n_prev + 1):EEG.nbchan;
  
  n_prev = EEG.nbchan;
  EEG = emg_pairs(EEG, opt.emg_band);
  emg_chans = (n_prev + 1):EEG.nbchan;
  
  if opt.save_intermediate
    % save the original raw dataset
    EEG = pop_saveset(EEG, 'filename', 'orig.set', 'filepath', opt.res_dir);
  end
  clear pat eog_pat
  
  %% reject bad epochs
  
  % remove bad epochs (using different algorithm than FASTER, so
  % it's easier to do here; turned off FASTER's epoch rejection
  amp_diffs = epoch_amp_diff(EEG, opt.eeg_chans);
  m = median(amp_diffs, 1);

  % plot epoch rejection information
  if opt.plot_epoch_rej
    plot_epoch_rej(amp_diffs, opt);
  end
  
  % remove epochs with high median amp differences; these probably
  % have electrical artifacts and are unsalvagable
  EEG = pop_select(EEG, 'notrial', find(m > opt.epoch_thresh));
  fprintf('Removed %d epochs.\n', nnz(m > opt.epoch_thresh))

  % save the data with bad epochs removed
  set_name = 'orig_epoch_rej.set';
  EEG = pop_saveset(EEG, 'filename', set_name, 'filepath', opt.res_dir);
  
  %% FASTER
  
  % set options. Just set the ones we can set with confidence based
  % on input to this function; leave the rest free to vary if the
  % users gives a custom options file
  load(opt.job_file, '-mat')
  
  % top level has GUI options; just need the lower level
  o = option_wrapper.options;
  if opt.save_intermediate
    o.save_options = true(1, 5);
  else
    o.save_options = false(1, 5);
  end
  
  % file options
  o.file_options.output_folder_name = opt.res_dir;
  o.file_options.current_file = fullfile(opt.res_dir, set_name);
  o.file_options.channel_locations = opt.locs_file;
  o.file_options.searchstring = EEG.setname;
  o.file_options.oplist = {opt.res_dir};
  o.file_options.using_ALLEEG = false;
  o.file_options.save_ALLEEG = false;
  o.using_ALLEEG = false;
  
  % channel options
  o.channel_options.do_reref = true;
  o.channel_options.ref_chan = opt.ref_chan;
  o.channel_options.eeg_chans = opt.eeg_chans;
  o.channel_options.ext_chans = union(eog_chans, emg_chans);
  o.channel_options.veog_chans = opt.veog_chans;
  o.channel_options.interp_after_ica = true;
  
  % epochs already defined, so turn off epoching
  o.epoch_options.markered_epoch = false;
  o.epoch_options.unmarkered_epoch = false;
  o.epoch_options.epoch_overlap = opt.epoch_overlap;
  o.epoch_options.epoch_rejection_on = true;

  % ICA options
  o.ica_options.ica_channels = setdiff(opt.eeg_chans, opt.ref_chan);
  o.ica_options.EOG_channels = eog_chans;
  o.ica_options.EMG_channels = emg_chans;
  
  % epoch-channel interpolation
  o.epoch_interp_options.epoch_interpolation_on = true;
  o.epoch_interp_options.rejection_options.amp_diff_thresh = opt.epoch_chan_thresh;
  o.epoch_interp_options.rejection_options.bad_epoch_thresh = opt.bad_chan_thresh;
  
  % GA
  o.make_GA = false;
  
  option_wrapper.options = o;

  % run FASTER
  log_file = fopen(fullfile(opt.res_dir, 'faster.log'), 'w');
  EEG = FASTER_process(option_wrapper, log_file);
  
  % save the processed output
  EEG = pop_saveset(EEG, 'filename', 'final.set', 'filepath', opt.res_dir);
  
  % convert back to pattern format
  pat = eeglab2pat(EEG);
  clear EEG
  pat.file = pat_file;
  
  
function plot_epoch_rej(amp_diffs, opt)

  m = median(amp_diffs, 1);
  figure
  subplot(4, 1, 1)
  imagesc(amp_diffs, [0 200]);
  subplot(4, 1, 2)
  plot(m);
  hold on
  set(gca, 'XLim', [0 size(amp_diffs, 2)])
  plot(get(gca, 'XLim'), repmat(opt.epoch_thresh, 1, 2), '-k')
  subplot(4, 1, 3)
  included = m <= opt.epoch_thresh;
  imagesc(amp_diffs(:,included), [0 200]);
  subplot(4, 1, 4)
  plot(sum(amp_diffs(:,included) > opt.epoch_chan_thresh, 1));
  set(gca, 'XLim', [0 nnz(included)])
  hold on
  plot(get(gca, 'XLim'), repmat(opt.bad_chan_thresh, 1, 2), '-k')

