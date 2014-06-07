function eeg_prop_plots(EEG, res_dir, base_name, ica)
%EEG_PROP_REPORT   Create report on properties of components.
%
%  eeg_prop_report(EEG, res_dir, base_name)

if nargin < 4
  ica = true;
  if nargin < 3
    base_name = 'prop';
  end
end

n_sample = 10;

res_dir = check_dir(res_dir);

% calculate properties for epoch sorting
if ica
  if ~isfield(EEG, 'icaact') || isempty(EEG.icaact)
    EEG.data = eeg_getica(EEG);
  else
    EEG.data = EEG.icaact;
    EEG.icaact = [];
  end
  n_comp = size(EEG.icawinv, 2);
  labels = cellfun(@(x) sprintf('IC%d', x), num2cell(1:n_comp), ...
                 'UniformOutput', false);
else
  n_comp = EEG.nbchan;
  labels = cellfun(@(x) sprintf('%d', x), num2cell(1:n_comp), ...
                 'UniformOutput', false);
end
epoch_comp_var = permute(var(EEG.data, [], 2), [3 1 2]);
ssfast = sum(diff(EEG.data, [], 2).^2, 2);
sstot = sum((EEG.data - ...
             repmat(mean(EEG.data, 2), [1 EEG.pnts 1])).^2, 2);
epoch_comp_fast = permute(ssfast ./ sstot, [3 1 2]);

if ica && isfield(EEG, 'chanlocs') && ~isempty(EEG.chanlocs)
  do_topo = true;
  n_figs = 5;
else
  do_topo = false;
  n_figs = 4;
end

f = figure;
temp_file = fullfile(res_dir, 'temp.png');
for i = 1:n_comp
  figure(f+1)
  clf reset
  figure(f)
  clf reset
  for j = 1:n_figs
    a{j} = axes('position', [.05 + .18 * (j-1) .1 .18 .8]);
  end
  
  n = 1;
  
  %% component topography
  if do_topo
    axes(a{n})
    topoplot(EEG.icawinv(:,i), EEG.chanlocs, 'chaninfo', EEG.chaninfo, ...
             'shading', 'interp', 'numcontour', 3);
    axis square
  end
  n = n + 1;
  
  %% ERP image
  x = EEG.data(i,:,:);
  figure(f+1)
  clf
  h = plot_erp_image(squeeze(x)', EEG.times);
  print(gcf, '-dpng', '-r400', temp_file)
  m = imread(temp_file);
  figure(f)
  axes(a{n})
  image(m)
  axis off
  n = n + 1;

  %% spectrum
  figure(f+1)
  clf
  if ica
    [spectra, freqs] = spectopo(x, EEG.pnts, EEG.srate, ...
                                'freqrange', [2 55], ...
                                'mapnorm', EEG.icawinv(:,i));
  else
    [spectra, freqs] = spectopo(x, EEG.pnts, EEG.srate, ...
                                'freqrange', [2 55]);
  end
  print(gcf, '-dpng', '-r400', temp_file)
  m = imread(temp_file);
  figure(f)
  axes(a{n})
  image(m)
  axis off
  n = n + 1;
  
  %% sample epochs based on variance
  
  figure(f+1)
  clf
  [~, ind] = sort(epoch_comp_var(:,i), 1, 'descend');
  for j = 1:n_sample
    subplot(n_sample, 1, j);
    plot(EEG.times, x(:,:,ind(j)), '-k', 'LineWidth', 2);
    if j < n_sample
      set(gca, 'XTickLabel', {}, 'XTick', [])
    end
    set(gca, 'XLim', [EEG.times(1) EEG.times(end)]);
  end
  xlabel('Time (ms)')
  print(gcf, '-dpng', '-r400', temp_file)
  m = imread(temp_file);
  figure(f)
  axes(a{n})
  image(m)
  axis off
  n = n + 1;

  %% sample epochs with fast changes
  figure(f+1)
  clf
  [~, ind] = sort(epoch_comp_fast(:,i), 1, 'descend');
  for j = 1:n_sample
    subplot(n_sample, 1, j);
    plot(EEG.times, x(:,:,ind(j)), '-k', 'LineWidth', 2);
    if j < n_sample
      set(gca, 'XTickLabel', {}, 'XTick', [])
    end
    set(gca, 'XLim', [EEG.times(1) EEG.times(end)]);
  end
  xlabel('Time (ms)')
  print(gcf, '-dpng', '-r400', temp_file)
  m = imread(temp_file);
  figure(f)
  axes(a{n})
  image(m)
  axis off
  n = n + 1;
  
  %set(gcf, 'PaperPosition', [.25 2.5 8 2])
  set(gcf, 'PaperPosition', [0 0 64 16])
  fig_name = sprintf('%s-%d.png', base_name, i);
  %print(f, '-dpng', '-r1200', fullfile(res_dir, fig_name));
  print(f, '-dpng', '-r400', fullfile(res_dir, fig_name));
end

