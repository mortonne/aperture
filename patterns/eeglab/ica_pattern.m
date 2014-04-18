function pat = ica_pattern(pat, varargin)

% options
def.locs_file = 'HCGSN128.loc';
def.reject_epochs = false;
def.epoch_thresh = 100;
def.save_intermediate = false;
def.plot_epoch_rej = false;
def.ica_chans = get_dim_vals(pat.dim, 'chan');
def.scratch_dir = '';
def.res_dir = '';
def.epoch_overlap = false;
def.k_value = 25;
def.basename = '';
def.finalname = '';
opt = propval(varargin, def);

%% export to EEGLAB

if isempty(opt.res_dir)
  opt.res_dir = get_pat_dir(pat, 'eeglab');
end
if isempty(opt.scratch_dir)
  opt.scratch_dir = get_pat_dir(pat, 'eeglab');
end
cd(opt.scratch_dir)

% start up EEGLAB (or restart if already running; this might affect
% previously loaded datasets, so save before running this function)
eeglab
EEG = pat2eeglab(pat, opt.locs_file);

if isempty(opt.basename)
  opt.basename = objfilename('eeg', pat.name, pat.source);
end

if opt.save_intermediate
  % save the original raw dataset
  EEG = pop_saveset(EEG, 'filename', [opt.basename '_orig.set'], ...
                    'filepath', opt.scratch_dir);
  pat = setobj(pat, 'elo', init_elo(EEG, 'name', 'orig'));
end

%% reject bad epochs

if opt.reject_epochs
  % remove bad epochs
  amp_diffs = epoch_amp_diff(EEG, opt.ica_chans);
  m = median(amp_diffs, 1);

  % plot epoch rejection information
  if opt.plot_epoch_rej
    plot_epoch_rej(amp_diffs, opt);
  end

  % remove epochs with high median amp differences; these probably
  % have electrical artifacts and are unsalvagable
  EEG = pop_select(EEG, 'notrial', find(m > opt.epoch_thresh));
  fprintf('Removed %d epochs.\n', nnz(m > opt.epoch_thresh))

  if opt.save_intermediate
    % save the data with bad epochs removed
    set_name = [opt.basename '_epoch_rej.set'];
    EEG = pop_saveset(EEG, 'filename', set_name, ...
                      'filepath', opt.scratch_dir);
    pat = setobj(pat, 'elo', init_elo(EEG, 'name', 'epoch_rej'));
  end
end
  
%% run ICA

if opt.epoch_overlap
  EEG = eeg_remove_epoch_overlap(EEG);
end

% max number of components that will be estimable given the
% number of samples we have
n_max_recommend = floor(sqrt(size(EEG.data(:,:), 2) / opt.k_value));
n_pca = min([n_max_recommend length(opt.ica_chans)]);

EEG = pop_runica(EEG, 'chanind', opt.ica_chans, ...
                 'icatype', 'binica', ...
                 'options', {'extended', 1, 'pca', n_pca});

if opt.epoch_overlap
  EEG = eeg_epoch_overlap(EEG);
end
             
%% save results

if isempty(opt.finalname)
  set_name = [opt.basename '_ica.set'];
else
  set_name = [opt.finalname '.set'];
end
EEG = pop_saveset(EEG, 'filename', set_name, 'filepath', opt.res_dir);

elo = init_elo(EEG, 'name', 'ica');
pat = setobj(pat, 'elo', elo);


function plot_epoch_rej(amp_diffs, opt)

  m = median(amp_diffs, 1);
  figure
  subplot(3, 1, 1)
  imagesc(amp_diffs, [0 200]);
  subplot(3, 1, 2)
  plot(m);
  hold on
  set(gca, 'XLim', [0 size(amp_diffs, 2)])
  plot(get(gca, 'XLim'), repmat(opt.epoch_thresh, 1, 2), '-k')
  subplot(3, 1, 3)
  included = m <= opt.epoch_thresh;
  imagesc(amp_diffs(:,included), [0 200]);
